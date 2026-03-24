//
//  Karte.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI
import MapKit

struct Karte: View {
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 52.5200,
                longitude: 13.4050
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    )

    var body: some View {
        Map(position: $position)
            .ignoresSafeArea()
    }
}

#Preview {
    Home()
}
