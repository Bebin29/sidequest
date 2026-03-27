//
//  RingCodeView.swift
//  Sidequest
//

import SwiftUI

struct RingCodeView: View {
    let code: String           // 96-char binary string
    let profileImage: UIImage?
    let initial: String
    let size: CGFloat

    private let ringCount = 4
    private let positionsPerRing = 24
    private let ringGap: CGFloat = 6
    private let strokeWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Rings
            ForEach(0..<ringCount, id: \.self) { ringIndex in
                RingLayer(
                    bits: bitsForRing(ringIndex),
                    radius: innerRadius + CGFloat(ringIndex) * ringGap + CGFloat(ringIndex) * strokeWidth,
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
        size - CGFloat(ringCount) * 2 * (ringGap + strokeWidth) - 8
    }

    private var innerRadius: CGFloat {
        profileSize / 2 + 4
    }

    private func bitsForRing(_ index: Int) -> [Bool] {
        let start = index * positionsPerRing
        let end = min(start + positionsPerRing, code.count)
        guard start < code.count else { return Array(repeating: false, count: positionsPerRing) }

        return code[code.index(code.startIndex, offsetBy: start)..<code.index(code.startIndex, offsetBy: end)]
            .map { $0 == "1" }
    }
}

// MARK: - Single Ring Layer

private struct RingLayer: View {
    let bits: [Bool]
    let radius: CGFloat
    let strokeWidth: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let segmentAngle = 2 * .pi / Double(bits.count)
            let gapAngle = segmentAngle * 0.3

            for (index, isOn) in bits.enumerated() {
                guard isOn else { continue }

                let startAngle = Double(index) * segmentAngle + gapAngle / 2 - .pi / 2
                let endAngle = startAngle + segmentAngle - gapAngle

                var path = Path()
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(endAngle),
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
