import SwiftUI

struct InvitationSwiper: View {
    
    
    var body: some View {
        ZStack {
            // Hintergrundbild
            if #available(iOS 26.0, *) {
                Image("Image01")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 400)
                    .clipped()
                    .glassEffect()
            } else {
                // Fallback on earlier versions
            }
            
            
        }
        .frame(width: 300, height: 400)
        .cornerRadius(25)
        .shadow(radius: 10)
    }
}
