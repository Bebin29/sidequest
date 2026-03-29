//
//  RingCodeView.swift
//  Sidequest
//
//  Renders a user's round code using the RoundCode library.
//  The code string is the user's UUID prefix (uppercase hex, max 27 chars).
//

import SwiftUI
import UIKit

struct RingCodeView: View {
    let code: String           // UUID-based message string for RoundCode
    let profileImage: UIImage?
    let initial: String
    let size: CGFloat

    var body: some View {
        ZStack {
            if let codeImage = generateRoundCode() {
                Image(uiImage: codeImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                // Fallback: empty circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            }

            // Profile image in center (RoundCode leaves the center open
            // for an attachment image, but we overlay it here for consistency)
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
        // RoundCode center area: size * imageScale (0.8)
        // Profile should fit inside the innermost ring with a small gap
        size * RCConstants.imageScale * 0.85
    }

    private func generateRoundCode() -> UIImage? {
        let coder = RCCoder(configuration: .uuidConfiguration)
        guard coder.validate(code) else { return nil }

        var rcImage = RCImage(message: code)
        rcImage.size = size * 3  // render at 3x for crispness
        rcImage.tintColors = [UIColor.white, UIColor.white]
        rcImage.isTransparent = true
        rcImage.attachmentImage = nil  // we overlay the profile ourselves

        return try? coder.encode(rcImage)
    }
}
