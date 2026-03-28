//
//  RingCodeScannerView.swift
//  Sidequest
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Scanner View

struct RingCodeScannerView: View {
    let currentUserId: UUID?
    let onUserFound: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var scanner = RingCodeScanner()
    @State private var isSearching = false
    @State private var statusText = "Ring-Code in den Kreis halten"
    @State private var hasDetection = false

    private let guideSize: CGFloat = 250

    var body: some View {
        NavigationStack {
            ZStack {
                ScannerCameraPreview(scanner: scanner)
                    .ignoresSafeArea()

                // Darkened edges with cutout
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .overlay(
                                Circle()
                                    .frame(width: guideSize + 20, height: guideSize + 20)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                    .allowsHitTesting(false)

                // Scan guide — exactly centered like the cutout
                ZStack {
                    Circle()
                        .stroke(
                            hasDetection ? Color.green.opacity(0.8) : Color.white.opacity(0.5),
                            lineWidth: hasDetection ? 3 : 2
                        )
                        .frame(width: guideSize, height: guideSize)
                        .animation(.easeInOut(duration: 0.3), value: hasDetection)

                    if isSearching {
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(Color.indigo, lineWidth: 3)
                            .frame(width: guideSize, height: guideSize)
                            .rotationEffect(.degrees(scanner.scanAngle))
                    }
                }

                // Status — pinned to bottom
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        if isSearching {
                            ProgressView().tint(.white)
                        }
                        Text(statusText)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Code scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onDisappear { scanner.stop() }
            .onChange(of: scanner.confirmedCode) { _, code in
                guard let code, !isSearching else { return }
                print("DEBUG DECODED:  \(code)")
                print("DEBUG EXPECTED: 110011010111101100100010110101000111111101111001100111110011011010011010100001000010111001100011")
                Task { await lookupUser(code: code) }
            }
            .onChange(of: scanner.hasCandidate) { _, value in
                hasDetection = value
            }
        }
    }

    private func lookupUser(code: String) async {
        isSearching = true
        statusText = "Suche User..."

        do {
            let user = try await FriendshipService().findUserByRingCode(code: code)
            if user.id != currentUserId {
                onUserFound(user)
                return
            } else {
                statusText = "Das ist dein eigener Code"
            }
        } catch {
            statusText = "Kein User gefunden"
        }

        isSearching = false
        try? await Task.sleep(for: .seconds(2))
        statusText = "Ring-Code in den Kreis halten"
        scanner.reset()
    }
}

// MARK: - Ring Code Scanner

final class RingCodeScanner: NSObject, ObservableObject {
    @Published var confirmedCode: String?
    @Published var hasCandidate = false
    @Published var scanAngle: Double = 0

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "ring-scanner", qos: .userInitiated)
    private var isSetup = false

    // Confidence system
    private var candidateCode: String?
    private var candidateCount = 0
    private let requiredConfidence = 3
    private var spinTimer: Timer?

    func setup() {
        guard !isSetup else { return }
        isSetup = true

        captureSession.sessionPreset = .medium // Lower res = faster processing

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }

        // Spinning animation
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.scanAngle += 3
            }
        }
    }

    func stop() {
        captureSession.stopRunning()
        spinTimer?.invalidate()
    }

    func reset() {
        candidateCode = nil
        candidateCount = 0
        confirmedCode = nil
        hasCandidate = false
        RingCodeDecoder.resetState()
    }

    fileprivate func processDetection(_ code: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let code else {
                if self.candidateCount > 0 {
                    self.candidateCount = max(0, self.candidateCount - 1)
                    if self.candidateCount == 0 {
                        self.hasCandidate = false
                    }
                }
                return
            }

            self.hasCandidate = true

            if code == self.candidateCode {
                self.candidateCount += 1
                if self.candidateCount >= self.requiredConfidence && self.confirmedCode == nil {
                    self.confirmedCode = code
                }
            } else {
                self.candidateCode = code
                self.candidateCount = 1
            }
        }
    }
}

extension RingCodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let code = RingCodeDecoder.decode(from: pixelBuffer)
        processDetection(code)
    }
}

// MARK: - Camera Preview

struct ScannerCameraPreview: UIViewRepresentable {
    let scanner: RingCodeScanner

    func makeUIView(context: Context) -> UIView {
        let view = ScannerPreviewUIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        scanner.setup()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class ScannerPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - Ring Code Decoder (gap-based detection on pixel buffer)

enum RingCodeDecoder {
    private static let ringCount = 4
    private static let positionsPerRing = 24
    private static let samplesPerPosition = 8
    private static let totalSamplesPerRing = positionsPerRing * samplesPerPosition // 192

    // Ring radii as fractions of pattern outer edge.
    // Derived from RingCodeView (size=130): innerRadius=31, step=9, outerEdge=60.5
    // Ring centers: 31, 40, 49, 58 → divided by 60.5
    private static let ringRadii: [CGFloat] = [0.51, 0.66, 0.81, 0.96]

    // Temporal smoothing for stable pattern radius
    private static var recentRadii: [CGFloat] = []
    private static let radiusHistorySize = 5

    static func resetState() {
        recentRadii.removeAll()
    }

    static func decode(from pixelBuffer: CVPixelBuffer) -> String? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)

        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = CGFloat(min(width, height)) / 2.5

        // 1. Find pattern radius with temporal smoothing (median of last N frames)
        guard let rawRadius = findPatternRadius(
            pointer: pointer, centerX: centerX, centerY: centerY,
            maxRadius: maxRadius, bytesPerRow: bytesPerRow,
            width: width, height: height
        ) else {
            print("DEBUG: findPatternRadius returned nil (maxRadius=\(maxRadius))")
            return nil
        }

        recentRadii.append(rawRadius)
        if recentRadii.count > radiusHistorySize { recentRadii.removeFirst() }
        guard recentRadii.count >= 3 else { return nil }
        let patternRadius = recentRadii.sorted()[recentRadii.count / 2]
        print("DEBUG: rawRadius=\(String(format: "%.1f", rawRadius)), patternRadius=\(String(format: "%.1f", patternRadius)), maxRadius=\(String(format: "%.1f", maxRadius))")

        // 2. Sample all 4 rings at high resolution
        var ringProfiles: [[CGFloat]] = []
        for ringIndex in 0..<ringCount {
            let radius = patternRadius * ringRadii[ringIndex]
            var profile: [CGFloat] = []
            for sample in 0..<totalSamplesPerRing {
                let angle = CGFloat(sample) / CGFloat(totalSamplesPerRing) * 2 * .pi
                let sx = CGFloat(centerX) + cos(angle) * radius
                let sy = CGFloat(centerY) + sin(angle) * radius
                profile.append(readLuma(pointer: pointer, x: Int(sx), y: Int(sy),
                                        width: width, height: height, bytesPerRow: bytesPerRow))
            }
            ringProfiles.append(profile)
        }

        // 3. Compute per-ring adaptive threshold
        let n = totalSamplesPerRing
        var ringThresholds: [CGFloat] = []
        for ring in 0..<ringCount {
            let sorted = ringProfiles[ring].sorted()
            let darkLevel = sorted[n / 5]       // 20th percentile
            let brightLevel = sorted[n * 4 / 5] // 80th percentile
            ringThresholds.append((darkLevel + brightLevel) / 2)
            print("DEBUG: ring \(ring) dark=\(String(format: "%.3f", darkLevel)) bright=\(String(format: "%.3f", brightLevel)) thresh=\(String(format: "%.3f", (darkLevel + brightLevel) / 2))")
        }

        // Helper: brightness at a position boundary (average ±1 sample for noise reduction)
        func boundaryBrightness(ring: Int, sample: Int) -> CGFloat {
            let p = ringProfiles[ring]
            return (p[(sample - 1 + n) % n] + p[sample] + p[(sample + 1) % n]) / 3.0
        }

        // 4. Find sync rotation — the boundary where all 4 rings are darkest simultaneously
        var bestRotation = 0
        var bestScore = 0
        var bestDarkness: CGFloat = 0
        for rotation in 0..<positionsPerRing {
            let sample = rotation * samplesPerPosition
            var score = 0
            var totalDarkness: CGFloat = 0
            for ring in 0..<ringCount {
                let b = boundaryBrightness(ring: ring, sample: sample)
                if b < ringThresholds[ring] {
                    score += 1
                    totalDarkness += ringThresholds[ring] - b
                }
            }
            if score > bestScore || (score == bestScore && totalDarkness > bestDarkness) {
                bestScore = score
                bestDarkness = totalDarkness
                bestRotation = rotation
            }
        }

        print("DEBUG: syncRotation=\(bestRotation) (sample \(bestRotation * samplesPerPosition)), score=\(bestScore)/4")
        guard bestScore >= 3 else {
            print("DEBUG: sync failed, bestScore=\(bestScore)")
            return nil
        }

        // 5. Decode bits — sample brightness at each position boundary
        //    Dark boundary = gap = "1" (new segment), Bright boundary = "0" (segment continues)
        var allBits = ""
        for ring in 0..<ringCount {
            var ringBits = ""
            for pos in 0..<positionsPerRing {
                let sample = ((bestRotation + pos) * samplesPerPosition) % n
                let b = boundaryBrightness(ring: ring, sample: sample)
                ringBits += b < ringThresholds[ring] ? "1" : "0"
            }
            print("DEBUG: ring \(ring) bits=\(ringBits) (ones=\(ringBits.filter { $0 == "1" }.count))")
            allBits += ringBits
        }

        // 6. Validate — each ring's first bit must be "1" (sync marker)
        for ring in 0..<ringCount {
            let idx = allBits.index(allBits.startIndex, offsetBy: ring * positionsPerRing)
            guard allBits[idx] == "1" else { return nil }
        }

        let ones = allBits.filter { $0 == "1" }.count
        print("DEBUG DECODED: \(allBits) (ones=\(ones))")
        guard ones >= 8 && ones <= 80 else {
            print("DEBUG: ones count out of range: \(ones)")
            return nil
        }

        return allBits
    }

    // MARK: - Pattern Radius Detection

    /// Find pattern radius by testing multiple candidates and scoring based on ring-code structure.
    /// The correct radius shows: high contrast on ALL 4 rings + strong sync (shared dark boundary).
    private static func findPatternRadius(
        pointer: UnsafePointer<UInt8>,
        centerX: Int, centerY: Int,
        maxRadius: CGFloat, bytesPerRow: Int,
        width: Int, height: Int
    ) -> CGFloat? {
        let numCandidates = 15
        let lowRes = 96 // 4 samples per position
        let lowResPerPos = lowRes / positionsPerRing // 4

        var bestRadius: CGFloat = 0
        var bestScore: CGFloat = 0

        for c in 0..<numCandidates {
            // Guide circle (250pt) ≈ 70px radius in camera buffer.
            // Ring code outer edge ≈ 65px when filling guide circle.
            // Search 25%-65% of maxRadius to stay within the ring code area.
            let fraction = 0.25 + CGFloat(c) * 0.40 / CGFloat(numCandidates - 1) // 0.25 to 0.65
            let candidateRadius = maxRadius * fraction

            // Sample all 4 rings at low resolution
            var ringProfiles: [[CGFloat]] = []
            var ringThresholds: [CGFloat] = []
            var minContrast: CGFloat = 1.0

            for ringIndex in 0..<ringCount {
                let radius = candidateRadius * ringRadii[ringIndex]
                var profile: [CGFloat] = []
                for a in 0..<lowRes {
                    let angle = CGFloat(a) / CGFloat(lowRes) * 2 * .pi
                    let sx = CGFloat(centerX) + cos(angle) * radius
                    let sy = CGFloat(centerY) + sin(angle) * radius
                    profile.append(readLuma(
                        pointer: pointer, x: Int(sx), y: Int(sy),
                        width: width, height: height, bytesPerRow: bytesPerRow
                    ))
                }
                let sorted = profile.sorted()
                let dark = sorted[lowRes / 5]
                let bright = sorted[lowRes * 4 / 5]
                ringThresholds.append((dark + bright) / 2)
                minContrast = min(minContrast, bright - dark)
                ringProfiles.append(profile)
            }

            // Skip if any ring lacks contrast
            guard minContrast > 0.05 else { continue }

            // Find best sync: position where ≥3 rings have a dark boundary, weighted by depth
            var bestSyncStrength: CGFloat = 0
            for rotation in 0..<positionsPerRing {
                let sample = rotation * lowResPerPos
                var count = 0
                var strength: CGFloat = 0
                for ring in 0..<ringCount {
                    let b = (ringProfiles[ring][(sample - 1 + lowRes) % lowRes] +
                             ringProfiles[ring][sample] +
                             ringProfiles[ring][(sample + 1) % lowRes]) / 3.0
                    if b < ringThresholds[ring] {
                        count += 1
                        strength += ringThresholds[ring] - b
                    }
                }
                if count >= 3 {
                    bestSyncStrength = max(bestSyncStrength, strength)
                }
            }

            guard bestSyncStrength > 0 else { continue }

            // Score: sync depth × minimum contrast — both must be high
            let score = bestSyncStrength * minContrast
            if score > bestScore {
                bestScore = score
                bestRadius = candidateRadius
            }
        }

        print("DEBUG: findRadius bestRadius=\(String(format: "%.1f", bestRadius)) score=\(String(format: "%.4f", bestScore)) maxR=\(String(format: "%.1f", maxRadius))")

        guard bestScore > 0 else {
            print("DEBUG: patternRadius not found")
            return nil
        }
        return bestRadius
    }

    // MARK: - Pixel Reading (BGRA → Luma)

    private static func readLuma(
        pointer: UnsafePointer<UInt8>,
        x: Int, y: Int,
        width: Int, height: Int,
        bytesPerRow: Int
    ) -> CGFloat {
        let cx = max(1, min(width - 2, x))
        let cy = max(1, min(height - 2, y))
        var total: CGFloat = 0
        for dy in -1...1 {
            for dx in -1...1 {
                let offset = (cy + dy) * bytesPerRow + (cx + dx) * 4
                let b = CGFloat(pointer[offset]) / 255.0
                let g = CGFloat(pointer[offset + 1]) / 255.0
                let r = CGFloat(pointer[offset + 2]) / 255.0
                total += 0.299 * r + 0.587 * g + 0.114 * b
            }
        }
        return total / 9.0
    }
}
