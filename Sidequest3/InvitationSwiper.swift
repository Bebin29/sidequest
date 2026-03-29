import SwiftUI

struct InvitationSwiper: View {
    
    var body: some View {
        if #available(iOS 26.0, *) {
            
            VStack {
                ZStack {
                    
                    Image("IMGSTART02")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 550)
                        .clipped()
                        .overlay(
                            
                            // Blur nur unten
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .mask(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .black.opacity(0.4),
                                            .black
                                        ],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .glassEffect(in: .rect(cornerRadius: 25))
                    VStack {
                        Text("Hallo")
                        Text("Hallo")
                    }
                   
                    
                }
                .frame(width: 350, height: 550)
                .cornerRadius(25)
                .shadow(radius: 10)
            }
            
        } else {
            // Fallback
        }
    }
}
