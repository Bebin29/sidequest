//
//  Feed.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Feed: View {
    var body: some View {
        
        HStack {
            Text("Feed")
                .fontWeight(.semibold)
                .padding()
                .foregroundStyle(Color(.white))
        }
        .background(Color(.systemIndigo))
        .cornerRadius(15)
        
    }
}

#Preview {
    Home()
}
