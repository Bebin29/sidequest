//
//  RingCodeScannerView.swift
//  Sidequest
//

import SwiftUI
import AVFoundation
import CoreImage

// MARK: - Scanner View

struct RingCodeScannerView: View {
    let currentUserId: UUID?
    let onUserFound: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var scanner = RingCodeScanner()
    @State private var isSearching = false
    @State private var statusText = "Ring-Code in den Kreis halten"
    @State private var lastLookupCode: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ScannerCameraPreview(scanner: scanner)
                    .ignoresSafeArea()

                // Darkened edges with cutout
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .overlay(
                                Circle()
                                    .frame(width: 260, height: 260)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                    .allowsHitTesting(false)

                VStack {
                    Spacer()

                    // Scan guide
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 220, height: 220)

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

        do {
            let user = try await FriendshipService().findUserByRingCode(code: code)
            if user.id != currentUserId {
                onUserFound(user)
            } else {
                statusText = "Das ist dein eigener Code"
                try? await Task.sleep(for: .seconds(2))
                statusText = "Ring-Code in den Kreis halten"
                lastLookupCode = nil
            }
        } catch {
            statusText = "Kein User gefunden"
            try? await Task.sleep(for: .seconds(2))
            statusText = "Ring-Code in den Kreis halten"
            lastLookupCode = nil
        }

        isSearching = false
    }
}

// MARK: - Ring Code Scanner (AVCaptureSession + Frame Processing)

@MainActor
final class RingCodeScanner: NSObject, ObservableObject {
    @Published var detectedCode: String?

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "ring-code-scanner", qos: .userInitiated)
    private var lastProcessTime = Date.distantPast
    private var isSetup = false

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
}

extension RingCodeScanner: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process max 3 frames per second
        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) > 0.33 else { return }
        lastProcessTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        if let code = RingCodeDecoder.decode(from: ciImage) {
            DispatchQueue.main.async { [weak self] in
                self?.detectedCode = code
            }
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

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // Session cleanup happens in scanner.stop()
    }
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
    // Ring layout matches RingCodeView: 3 rings, 24 positions each
    private static let ringCount = 3
    private static let positionsPerRing = 24

    // Relative ring radii (fraction of crop region radius)
    // These match the RingCodeView layout proportions
    private static let ringRadii: [CGFloat] = [0.55, 0.72, 0.89]

    /// Decode a ring code from a camera frame.
    /// Returns a 72-character binary string, or nil if no valid pattern found.
    static func decode(from ciImage: CIImage) -> String? {
        let extent = ciImage.extent

        // Crop to center square
        let side = min(extent.width, extent.height) * 0.5
        let cropRect = CGRect(
            x: extent.midX - side / 2,
            y: extent.midY - side / 2,
            width: side,
            height: side
        )

        let cropped = ciImage.cropped(to: cropRect)

        // Convert to grayscale CGImage for pixel access
        let context = CIContext()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else { return nil }
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
            var brightnesses: [CGFloat] = []

            // Sample brightness at 24 positions around the ring
            for position in 0..<positionsPerRing {
                let angle = CGFloat(position) / CGFloat(positionsPerRing) * 2 * .pi - .pi / 2

                let sampleX = Int(centerX + cos(angle) * radius)
                let sampleY = Int(centerY - sin(angle) * radius)

                // Sample a small area (3×3) for stability
                var totalBrightness: CGFloat = 0
                var sampleCount: CGFloat = 0

                for deltaX in -1...1 {
                    for deltaY in -1...1 {
                        let pixelX = max(0, min(width - 1, sampleX + deltaX))
                        let pixelY = max(0, min(height - 1, sampleY + deltaY))
                        let offset = pixelY * bytesPerRow + pixelX * bytesPerPixel

                        // Use luminance from RGB
                        let red = CGFloat(pointer[offset]) / 255.0
                        let green = CGFloat(pointer[offset + 1]) / 255.0
                        let blue = CGFloat(pointer[offset + 2]) / 255.0
                        totalBrightness += 0.299 * red + 0.587 * green + 0.114 * blue
                        sampleCount += 1
                    }
                }

                brightnesses.append(totalBrightness / sampleCount)
            }

            // Find gaps: positions where brightness drops significantly
            // A gap is a segment boundary → bit = 1
            let avgBrightness = brightnesses.reduce(0, +) / CGFloat(brightnesses.count)
            let threshold = avgBrightness * 0.7

            // Check each position: is it in a gap (dark) or a segment (bright)?
            var isGap = brightnesses.map { $0 < threshold }

            // Convert gaps to bits: a gap at position i means position i starts a new segment
            // bit[i] = 1 if there's a gap just before position i
            var bits = ""
            for position in 0..<positionsPerRing {
                let prevPos = (position - 1 + positionsPerRing) % positionsPerRing
                // If current is bright but previous was dark (gap), this starts a new segment
                if isGap[prevPos] && !isGap[position] {
                    bits += "1"
                } else if isGap[position] {
                    // In a gap — this could be a boundary, but we encode it as continuation
                    bits += "1"
                } else {
                    bits += "0"
                }
            }

            allBits += bits
        }

        // Validate: should have some variety (not all same)
        let ones = allBits.filter { $0 == "1" }.count
        guard ones > 5 && ones < 67 else { return nil }

        return allBits
    }
}
