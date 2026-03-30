import SwiftUI
import MapKit

struct Karte: View {

    @StateObject private var locationManager = LocationManager()
    var mapViewModel: MapViewModel
    @State private var showFilterSheet = false
    @State private var selectedLocationId: UUID?
    @State private var showDetail = false

    var userId: UUID?
    @Binding var focusLocation: Location?

    var body: some View {
        ZStack {
            Map(position: $locationManager.position, selection: $selectedLocationId) {
                UserAnnotation()
                ForEach(mapViewModel.locations) { location in
                    Annotation(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude

                    )) {
                        LocationPin(imageUrl: location.imageUrls.first)
                            .tag(location.id)
                    }
                }
            }
            .ignoresSafeArea(.container)
            .onChange(of: selectedLocationId) { _, newValue in
                if newValue != nil {
                    showDetail = true
                }
            }
            .onChange(of: focusLocation, initial: true) { _, location in
                guard let location else { return }
                locationManager.positionOverridden = true
                withAnimation(.easeInOut(duration: 0.6)) {
                    locationManager.position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                    selectedLocationId = location.id
                }
                focusLocation = nil
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {

                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: mapViewModel.filter.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.35),
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }

                        Button {
                            locationManager.centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.35),
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }

                    }.padding()

                }
            }
        }

        .sheet(isPresented: $showFilterSheet) {
            LocationFilterView(
                mapViewModel: mapViewModel,
                userLatitude: locationManager.lastLocation?.coordinate.latitude,
                userLongitude: locationManager.lastLocation?.coordinate.longitude,
                onApply: {
                    guard let userId else { return }
                    Task { await mapViewModel.loadLocations(userId: userId) }
                }
            )
        }
        .task {
            guard let userId else { return }
            await mapViewModel.loadLocations(userId: userId)
        }
        .sheet(isPresented: $showDetail, onDismiss: {
            selectedLocationId = nil
            guard let userId else { return }
            Task { await mapViewModel.loadLocations(userId: userId) }
        }) {
            if let location = mapViewModel.locations.first(where: { $0.id == selectedLocationId }) {
                NavigationStack {
                    LocationDetailView(location: location, currentUserId: userId, onDelete: {
                        mapViewModel.locations.removeAll { $0.id == location.id }
                        showDetail = false
                    }, onUpdate: { updated in
                        if let index = mapViewModel.locations.firstIndex(where: { $0.id == updated.id }) {
                            mapViewModel.locations[index] = updated
                        }
                    })
                }
            }
        }
    }
}
