//
//  RingCodeScannerView.swift
//  Sidequest
//

import SwiftUI
import AVFoundation
import CoreImage

struct RingCodeScannerView: View {
    let currentUserId: UUID?
    let onUserFound: (User) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var foundUser: User?
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview()
                    .ignoresSafeArea()

                // Overlay guide
                VStack {
                    Spacer()

                    // Scan target circle
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 220, height: 220)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 40)
                        )

                    Spacer().frame(height: 40)

                    // Status
                    Group {
                        if isSearching {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Suche User...")
                            }
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                        } else {
                            Text("Ring-Code in den Kreis halten")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.6))
                    .clipShape(Capsule())

                    Spacer().frame(height: 60)
                }

                // Darkened edges
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
        }
    }
}

// MARK: - Camera Preview (AVCaptureSession)

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraUIView {
        CameraUIView()
    }

    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}

class CameraUIView: UIView {
    private var captureSession: AVCaptureSession?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = bounds
        }
    }

    deinit {
        captureSession?.stopRunning()
    }
}
