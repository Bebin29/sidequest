//
//  LocationPin.swift
//  Sidequest
//

import SwiftUI

struct LocationPin: View {
    let imageUrl: String?

    var body: some View {
        VStack(spacing: 0) {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                        .overlay(ProgressView().controlSize(.small))
                }
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(radius: 3)
            } else {
                Circle()
                    .fill(.blue)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.white)
                            .font(.body.bold())
                    )
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .shadow(radius: 3)
            }

            
            
        }
    }
}
#Preview {
    LocationPin(imageUrl: "Image01")
}
