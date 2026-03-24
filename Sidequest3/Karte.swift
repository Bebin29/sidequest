//
//  Karte.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.region.center = location.coordinate
        }
    }
}

struct Karte: View {
    
    @StateObject private var locationManager = LocationManager()
    
    let places = [
        CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00258),
        CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00268),
        CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00278)
    ]
    
    var body: some View {
        Map(coordinateRegion: $locationManager.region,
            showsUserLocation: true,
            annotationItems: places) { place in
            
            MapMarker(coordinate: place)
        }
        .ignoresSafeArea()
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)\(longitude)"
    }
}

#Preview {
    Home()
}
