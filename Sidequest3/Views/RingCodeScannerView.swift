//
//  RingCodeScannerView.swift
//  Sidequest
//

import SwiftUI
import AVFoundation
import CoreImage
import Combine

// MARK: - Scanner View

struct RingCodeScannerView: View {
    let currentUserId: UUID?
    let onUserFound: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var scanner = RingCodeScanner()
    @State private var isSearching = false
    @State private var statusText = "Ring-Code in den Kreis halten"
    @State private var lastLookupCode: String?

    private let guideSize: CGFloat = 240

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
                                    .frame(width: guideSize, height: guideSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                    .allowsHitTesting(false)

                VStack {
                    Spacer()

                    // Scan guide — same size as cutout
                    Circle()
                        .stroke(.white.opacity(0.7), lineWidth: 2)
                        .frame(width: guideSize, height: guideSize)

                    Spacer().frame(height: 40)

                    // Status
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

                    Spacer().frame(height: 60)
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
            .onChange(of: scanner.detectedCode) { _, code in
                guard let code, code != lastLookupCode, !isSearching else { return }
                lastLookupCode = code
                Task { await lookupUser(code: code) }
            }
        }
    }

    private func lookupUser(code: String) async {
        isSearching = true
        statusText = "Suche User..."

        // Try all 24 rotations (phone might be rotated)
        let found = await tryAllRotations(code: code)

        if let user = found {
            if user.id != currentUserId {
                onUserFound(user)
                return
            } else {
                statusText = "Das ist dein eigener Code"
            }
        } else {
            statusText = "Kein User gefunden — erneut versuchen"
        }

        isSearching = false
        try? await Task.sleep(for: .seconds(2))
        statusText = "Ring-Code in den Kreis halten"
        lastLookupCode = nil
    }

    private func tryAllRotations(code: String) async -> User? {
        let service = FriendshipService()
        let rings = stride(from: 0, to: 72, by: 24).map { start in
            let idx = code.index(code.startIndex, offsetBy: start)
            let end = code.index(idx, offsetBy: 24)
            return String(code[idx..<end])
        }

        // Try each rotation offset (all 3 rings rotate together)
        for offset in 0..<24 {
            let rotated = rings.map { ring -> String in
                let idx = ring.index(ring.startIndex, offsetBy: offset)
                return String(ring[idx...]) + String(ring[..<idx])
            }.joined()

            if let user = try? await service.findUserByRingCode(code: rotated) {
                return user
            }
        }
        return nil
    }
}

// MARK: - Ring Code Scanner

final class RingCodeScanner: NSObject, ObservableObject {
    @Published var detectedCode: String?

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "ring-code-scanner", qos: .userInitiated)
    private var isSetup = false

    // Confidence: require same code N times in a row
    private var candidateCode: String?
    private var candidateCount = 0
    private let requiredConfidence = 3


    func setup() {
        guard !isSetup else { return }
        isSetup = true

        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)

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

    fileprivate func processCode(_ code: String?) {
        guard let code else {
            candidateCode = nil
            candidateCount = 0
            return
        }

        if code == candidateCode {
            candidateCount += 1
            if candidateCount >= requiredConfidence {
                detectedCode = code
                candidateCount = 0
                candidateCode = nil
            }
        } else {
            candidateCode = code
            candidateCount = 1
        }
    }
}

extension RingCodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let code = RingCodeDecoder.decode(from: ciImage)

        DispatchQueue.main.async { [weak self] in
            self?.processCode(code)
        }
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

// MARK: - Ring Code Decoder

enum RingCodeDecoder {
    private static let ringCount = 3
    private static let positionsPerRing = 24

    // Relative ring radii — must match RingCodeView proportions
    private static let ringRadii: [CGFloat] = [0.55, 0.72, 0.89]

    static func decode(from ciImage: CIImage) -> String? {
        let extent = ciImage.extent

        // Crop center square (40% of image for tighter focus)
        let side = min(extent.width, extent.height) * 0.4
        let cropRect = CGRect(
            x: extent.midX - side / 2,
            y: extent.midY - side / 2,
            width: side,
            height: side
        )

        let cropped = ciImage.cropped(to: cropRect)

        let context = CIContext()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else { return nil }

        // Get pixel data
        guard let data = cgImage.dataProvider?.data,
              let pointer = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let centerX = CGFloat(width) / 2
        let centerY = CGFloat(height) / 2
        let maxRadius = CGFloat(min(width, height)) / 2

        var allBits = ""

        for ringIndex in 0..<ringCount {
            let radius = maxRadius * ringRadii[ringIndex]

            // Sample brightness at each position with 5x5 kernel
            var brightnesses: [CGFloat] = []
            for position in 0..<positionsPerRing {
                let angle = CGFloat(position) / CGFloat(positionsPerRing) * 2 * .pi - .pi / 2
                let sampleX = centerX + cos(angle) * radius
                let sampleY = centerY - sin(angle) * radius

                let brightness = sampleBrightness(
                    pointer: pointer, x: sampleX, y: sampleY,
                    width: width, height: height,
                    bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow,
                    kernelSize: 2
                )
                brightnesses.append(brightness)
            }

            // Adaptive threshold per ring
            let sorted = brightnesses.sorted()
            let median = sorted[sorted.count / 2]
            let minBright = sorted.first ?? 0
            let threshold = minBright + (median - minBright) * 0.5

<<<<<<< HEAD
            // Check each position: is it in a gap (dark) or a segment (bright)?
            let isGap = brightnesses.map { $0 < threshold }
=======
            // Classify each position
            let isSegment = brightnesses.map { $0 > threshold }
>>>>>>> 87ef9084a0cb4165ff893f055880d32536d970fe

            // Convert to bits: detect transitions from gap to segment
            var bits = ""
            for position in 0..<positionsPerRing {
                let prev = (position - 1 + positionsPerRing) % positionsPerRing
                if isSegment[position] && !isSegment[prev] {
                    // Transition from gap to segment → new segment starts
                    bits += "1"
                } else if !isSegment[position] {
                    // In a gap → mark as boundary
                    bits += "1"
                } else {
                    // Continuation of segment
                    bits += "0"
                }
            }

            allBits += bits
        }

        // Validate: reasonable distribution
        let ones = allBits.filter { $0 == "1" }.count
        guard ones > 8 && ones < 60 else { return nil }

        return allBits
    }

    private static func sampleBrightness(
        pointer: UnsafePointer<UInt8>,
        x: CGFloat, y: CGFloat,
        width: Int, height: Int,
        bytesPerPixel: Int, bytesPerRow: Int,
        kernelSize: Int
    ) -> CGFloat {
        var total: CGFloat = 0
        var count: CGFloat = 0

        for deltaX in -kernelSize...kernelSize {
            for deltaY in -kernelSize...kernelSize {
                let pixelX = max(0, min(width - 1, Int(x) + deltaX))
                let pixelY = max(0, min(height - 1, Int(y) + deltaY))
                let offset = pixelY * bytesPerRow + pixelX * bytesPerPixel

                let red = CGFloat(pointer[offset]) / 255.0
                let green = CGFloat(pointer[offset + 1]) / 255.0
                let blue = CGFloat(pointer[offset + 2]) / 255.0
                total += 0.299 * red + 0.587 * green + 0.114 * blue
                count += 1
            }
        }

        return total / count
    }
}
