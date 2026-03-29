//
//  RingCodeScannerView.swift
//  Sidequest
//
//  Camera scanner that decodes RoundCode patterns using the RoundCode library.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Scanner View

struct RingCodeScannerView: View {
    let currentUserId: UUID?
    let onUserFound: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var scanner = RoundCodeScanner()
    @State private var isSearching = false
    @State private var statusText = "Code in den Kreis halten"
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

                // Scan guide
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
                print("DEBUG: RoundCode decoded message: \(code)")
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
        statusText = "Code in den Kreis halten"
        scanner.reset()
    }
}

// MARK: - RoundCode Scanner (AVCapture + RCCoder)

final class RoundCodeScanner: NSObject, ObservableObject {
    @Published var confirmedCode: String?
    @Published var hasCandidate = false
    @Published var scanAngle: Double = 0

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "roundcode-scanner", qos: .userInitiated)
    private var isSetup = false

    // Confidence system
    private var candidateCode: String?
    private var candidateCount = 0
    private let requiredConfidence = 3
    private var spinTimer: Timer?

    // RoundCode decoder
    private let coder: RCCoder = {
        let c = RCCoder(configuration: .uuidConfiguration)
        c.scanningMode = .darkBackground  // white code on dark background
        return c
    }()

    func setup() {
        guard !isSetup else { return }
        isSetup = true

        captureSession.sessionPreset = .hd1280x720

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)

        // RoundCode expects YCbCr luma plane — same format as original RCCameraViewController
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)

        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)

        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        spinTimer?.invalidate()
        spinTimer = nil
    }

    func reset() {
        candidateCode = nil
        candidateCount = 0
        confirmedCode = nil
        hasCandidate = false
        spinTimer?.invalidate()
        spinTimer = nil
    }
}

// MARK: - Video Frame Processing

extension RoundCodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoRotationAngle = 90  // portrait

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        // Extract square luma region from center (same approach as RCCameraViewController)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let bufferHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bufferWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let size = min(bufferWidth, bufferHeight)
        let origin = (max(bufferWidth, bufferHeight) - size) / 2

        guard let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)?.advanced(by: bytesPerRow * origin) else { return }

        // Copy luma data to mutable buffer
        let lumaCopy = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * size, alignment: MemoryLayout<UInt8>.alignment)
        lumaCopy.copyMemory(from: lumaBaseAddress, byteCount: bytesPerRow * size)
        defer { lumaCopy.deallocate() }

        // Configure decoder dimensions
        coder.imageDecoder.size = size
        coder.imageDecoder.bytesPerRow = bytesPerRow

        // Try to decode
        guard let message = try? coder.decode(buffer: lumaCopy.assumingMemoryBound(to: UInt8.self)) else {
            // No code detected this frame
            DispatchQueue.main.async { [weak self] in
                self?.hasCandidate = false
            }
            return
        }

        // Confidence: require N consecutive identical reads
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasCandidate = true

            if message == self.candidateCode {
                self.candidateCount += 1
            } else {
                self.candidateCode = message
                self.candidateCount = 1
            }

            if self.candidateCount >= self.requiredConfidence && self.confirmedCode == nil {
                self.confirmedCode = message
                self.startSpinner()
            }
        }
    }

    private func startSpinner() {
        spinTimer?.invalidate()
        spinTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.scanAngle += 4
        }
    }
}

// MARK: - Camera Preview (UIKit wrapper)

struct ScannerCameraPreview: UIViewRepresentable {
    let scanner: RoundCodeScanner

    func makeUIView(context: Context) -> ScannerPreviewUIView {
        let view = ScannerPreviewUIView()
        view.previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        view.previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(view.previewLayer!)
        scanner.setup()
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewUIView, context: Context) {}
}

class ScannerPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
