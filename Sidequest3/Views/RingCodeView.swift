//
//  RingCodeView.swift
//  Sidequest
//

import SwiftUI

struct RingCodeView: View {
    let code: String           // 72-char binary string (3 rings × 24 positions)
    let profileImage: UIImage?
    let initial: String
    let size: CGFloat

    private let ringCount = 3
    private let positionsPerRing = 24
    private let ringSpacing: CGFloat = 8
    private let strokeWidth: CGFloat = 5

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { ringIndex in
                RingLayer(
                    segments: segmentsForRing(ringIndex),
                    radius: innerRadius + CGFloat(ringIndex) * (ringSpacing + strokeWidth),
                    strokeWidth: strokeWidth
                )
            }

            // Profile image in center
            Group {
                if let profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.white.opacity(0.15)
                        .overlay(
                            Text(initial)
                                .font(.system(size: profileSize * 0.4, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: profileSize, height: profileSize)
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }

    private var profileSize: CGFloat {
        size - CGFloat(ringCount) * 2 * (ringSpacing + strokeWidth) - 8
    }

    private var innerRadius: CGFloat {
        profileSize / 2 + 6
    }

    /// Convert bits into segments: each segment has a start position and a length.
    /// A "1" bit means "start a new segment", "0" means "continue previous segment".
    /// This way the ring is always fully filled — only the segment boundaries change.
    private func segmentsForRing(_ ringIndex: Int) -> [RingSegment] {
        let start = ringIndex * positionsPerRing
        let end = min(start + positionsPerRing, code.count)
        guard start < code.count else { return [RingSegment(start: 0, length: positionsPerRing)] }

        let bits = code[code.index(code.startIndex, offsetBy: start)..<code.index(code.startIndex, offsetBy: end)]
            .map { $0 == "1" }

        var segments: [RingSegment] = []
        var currentStart = 0
        var currentLength = 1

        for position in 1..<bits.count {
            if bits[position] {
                // New segment boundary
                segments.append(RingSegment(start: currentStart, length: currentLength))
                currentStart = position
                currentLength = 1
            } else {
                currentLength += 1
            }
        }
        // Close last segment
        segments.append(RingSegment(start: currentStart, length: currentLength))

        return segments
    }
}

struct RingSegment {
    let start: Int
    let length: Int
}

// MARK: - Single Ring Layer

private struct RingLayer: View {
    let segments: [RingSegment]
    let radius: CGFloat
    let strokeWidth: CGFloat

    private let totalPositions = 24
    private let gapAngle = 0.03  // Small gap between segments (radians)

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let slotAngle = 2 * .pi / Double(totalPositions)

            for segment in segments {
                let startRad = Double(segment.start) * slotAngle + gapAngle / 2 - .pi / 2
                let endRad = startRad + Double(segment.length) * slotAngle - gapAngle

                var path = Path()
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .radians(startRad),
                    endAngle: .radians(endRad),
                    clockwise: false
                )

                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
            }
        }
    }
}
