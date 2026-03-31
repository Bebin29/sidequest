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
    @State private var spinAngle: Double = 0

    private let guideSize: CGFloat = 250

    var body: some View {
        NavigationStack {
            ZStack {
                if scanner.cameraAccessDenied {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Kamerazugriff benoetigt")
                            .font(.headline)
                        Text("Erlaube Sidequest den Kamerazugriff in den Einstellungen, um Ring-Codes zu scannen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Einstellungen oeffnen") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
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

                VStack(spacing: 0) {
                    Spacer()

                    // Scan guide — centered, same position as cutout
                    ZStack {
                        Circle()
                            .stroke(
                                hasDetection ? Theme.success.opacity(0.8) : Theme.textSecondary,
                                lineWidth: hasDetection ? 3 : 2
                            )
                            .frame(width: guideSize, height: guideSize)
                            .animation(.easeInOut(duration: 0.3), value: hasDetection)

                        if isSearching {
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Theme.accent, lineWidth: 3)
                                .frame(width: guideSize, height: guideSize)
                                .rotationEffect(.degrees(spinAngle))
                        }
                    }

                    Spacer()

                    // Status — pinned to bottom
                    HStack(spacing: 8) {
                        if isSearching {
                            ProgressView().tint(.white)
                        }
                        Text(statusText)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
                }
                } // else (camera available)
            }
            .navigationTitle("Code scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .onDisappear { scanner.stop() }
            .onChange(of: scanner.confirmedCode) { _, code in
                guard let code, !isSearching else { return }
                Task { await lookupUser(code: code) }
            }
            .onChange(of: scanner.hasCandidate) { _, value in
                hasDetection = value
            }
            .onChange(of: isSearching) { _, searching in
                if searching {
                    withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
                        spinAngle = 360
                    }
                } else {
                    spinAngle = 0
                }
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
    @Published var cameraAccessDenied = false

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "ring-scanner", qos: .userInitiated)
    private var isSetup = false

    // Confidence system
    private var candidateCode: String?
    private var candidateCount = 0
    private let requiredConfidence = 3

    func setup() {
        guard !isSetup else { return }
        isSetup = true

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureSession()
                } else {
                    DispatchQueue.main.async { self?.cameraAccessDenied = true }
                }
            }
        default:
            DispatchQueue.main.async { self.cameraAccessDenied = true }
        }
    }

    private func configureSession() {
        captureSession.sessionPreset = .medium

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
    }

    func stop() {
        captureSession.stopRunning()
    }

    func reset() {
        candidateCode = nil
        candidateCount = 0
        confirmedCode = nil
        hasCandidate = false
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

// MARK: - Ring Code Decoder (works directly on pixel buffer — no CIContext overhead)

enum RingCodeDecoder {
    private static let ringCount = 3
    private static let positionsPerRing = 24
    private static let samplesPerPosition = 3

    // Ring radii as fractions of detected pattern radius
    // Calculated from RingCodeView: innerRadius + ringIndex * (gapSize + strokeWidth)
    // With gapSize=7, strokeWidth=5: ratios are ~0.48, 0.66, 0.85
    private static let ringRadii: [CGFloat] = [0.73, 0.87, 1.0]

    static func decode(from pixelBuffer: CVPixelBuffer) -> String? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Work in center crop area
        let cropSize = min(width, height) / 2
        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = CGFloat(cropSize) / 2

        // Try to find the ring pattern by scanning for brightness contrast
        // The rings are white on a dark background — look for a radial brightness profile
        guard let patternRadius = findPatternRadius(
            pointer: pointer, centerX: centerX, centerY: centerY,
            maxRadius: maxRadius, bytesPerRow: bytesPerRow,
            width: width, height: height
        ) else { return nil }

        var allBits = ""

        for ringIndex in 0..<ringCount {
            let radius = patternRadius * ringRadii[ringIndex]

            // High-resolution sampling: 24 positions × samplesPerPosition
            let totalSamples = positionsPerRing * samplesPerPosition
            var brightnesses: [CGFloat] = []

            for sample in 0..<totalSamples {
                let angle = CGFloat(sample) / CGFloat(totalSamples) * 2 * .pi
                let sampleX = CGFloat(centerX) + cos(angle) * radius
                let sampleY = CGFloat(centerY) + sin(angle) * radius

                let brightness = readBrightness(
                    pointer: pointer, x: Int(sampleX), y: Int(sampleY),
                    width: width, height: height, bytesPerRow: bytesPerRow
                )
                brightnesses.append(brightness)
            }

            // Average down to 24 positions
            var positionBrightness: [CGFloat] = []
            for pos in 0..<positionsPerRing {
                var sum: CGFloat = 0
                for sub in 0..<samplesPerPosition {
                    sum += brightnesses[pos * samplesPerPosition + sub]
                }
                positionBrightness.append(sum / CGFloat(samplesPerPosition))
            }

            // Find gaps using gradient detection
            let bits = detectSegmentBoundaries(brightnesses: positionBrightness)
            guard bits.count == positionsPerRing else { return nil }
            allBits += bits
        }

        // Validate
        let ones = allBits.filter { $0 == "1" }.count
        guard ones >= 6 && ones <= 60 else { return nil }

        return allBits
    }

    /// Scan radially outward to find the approximate size of the ring pattern.
    /// Returns the outer radius of the pattern, or nil if no pattern detected.
    private static func findPatternRadius(
        pointer: UnsafePointer<UInt8>,
        centerX: Int, centerY: Int,
        maxRadius: CGFloat, bytesPerRow: Int,
        width: Int, height: Int
    ) -> CGFloat? {
        let numAngles = 8
        let numSteps = 30
        var radialProfile: [CGFloat] = Array(repeating: 0, count: numSteps)

        for angleIdx in 0..<numAngles {
            let angle = CGFloat(angleIdx) / CGFloat(numAngles) * 2 * .pi
            for step in 0..<numSteps {
                let radius = maxRadius * CGFloat(step + 1) / CGFloat(numSteps)
                let sampleX = CGFloat(centerX) + cos(angle) * radius
                let sampleY = CGFloat(centerY) + sin(angle) * radius

                let brightness = readBrightness(
                    pointer: pointer,
                    x: Int(sampleX), y: Int(sampleY),
                    width: width, height: height,
                    bytesPerRow: bytesPerRow
                )
                radialProfile[step] += brightness / CGFloat(numAngles)
            }
        }

        // Find the outermost ring: look for last significant brightness peak
        let avg = radialProfile.reduce(0, +) / CGFloat(numSteps)
        var lastBrightStep = 0
        for step in stride(from: numSteps - 1, through: 0, by: -1) {
            if radialProfile[step] > avg * 1.2 {
                lastBrightStep = step
                break
            }
        }

        guard lastBrightStep > 5 else { return nil } // Too small or not found

        // Outer ring radius = pattern radius (ringRadii[2] = 1.0)
        let outerRingRadius = maxRadius * CGFloat(lastBrightStep + 1) / CGFloat(numSteps)
        return outerRingRadius
    }

    /// Detect segment boundaries from a ring's brightness profile.
    /// Returns a 24-char binary string where "1" = new segment starts here.
    private static func detectSegmentBoundaries(brightnesses: [CGFloat]) -> String {
        let count = brightnesses.count
        guard count == positionsPerRing else { return "" }

        // Find min and max for this ring
        let minVal = brightnesses.min() ?? 0
        let maxVal = brightnesses.max() ?? 1
        let range = maxVal - minVal

        // Need sufficient contrast
        guard range > 0.05 else { return String(repeating: "0", count: count) }

        // Threshold: midpoint between min and max
        let threshold = minVal + range * 0.45

        // Classify each position
        let isSegment = brightnesses.map { $0 > threshold }

        // Build bit string: "1" where a new segment begins (transition from dark to bright)
        var bits = ""
        for pos in 0..<count {
            let prev = (pos - 1 + count) % count
            if isSegment[pos] && !isSegment[prev] {
                bits += "1" // Gap→Segment transition = new segment
            } else if !isSegment[pos] && isSegment[prev] {
                bits += "1" // Segment→Gap = this is a gap position, mark as boundary
            } else if !isSegment[pos] {
                bits += "1" // In a gap
            } else {
                bits += "0" // In a segment, no boundary
            }
        }

        return bits
    }

    /// Read brightness at a pixel position (BGRA format), averaged over 3×3 area.
    private static func readBrightness(
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
                let blue = CGFloat(pointer[offset]) / 255.0
                let green = CGFloat(pointer[offset + 1]) / 255.0
                let red = CGFloat(pointer[offset + 2]) / 255.0
                total += 0.299 * red + 0.587 * green + 0.114 * blue
            }
        }
        return total / 9.0
    }
}
