//
//  PlaceSearchView.swift
//  Sidequest3
//
//  Created by ole on 30.03.26.
//

import SwiftUI
import MapKit

struct PlaceSearchView: View {

    @State private var searchText = ""
    @StateObject private var completer = SearchCompleter()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedItem: MKMapItem?
    @State private var selectedCategory = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @Bindable var mapViewModel: MapViewModel
    var userId: UUID?
    var onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            if let item = selectedItem {
                AddLocationFormView(
                    mapItem: item,
                    category: selectedCategory,
                    mapViewModel: mapViewModel,
                    userId: userId,
                    onDismiss: onDismiss,
                    onBack: { selectedItem = nil }
                )
            } else {
                VStack {
                    TextField("Ort suchen", text: $searchText)
                        .padding()
                        .background(
                            // Liquid Glass Effekt
                            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        )
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .onChange(of: searchText) { _, newValue in
                            searchDebounceTask?.cancel()
                            searchDebounceTask = Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                guard !Task.isCancelled else { return }
                                completer.userLocation = locationManager.lastLocation
                                completer.update(query: newValue)
                            }
                        }
                                            

                    List(completer.results) { result in
                        Button {
                            resolveAndSelect(result.completion)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(result.completion.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(result.completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if let distance = result.formattedDistance {
                                    Text(distance)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .navigationTitle("Ort suchen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                            
                        }
                    }
                }
            }
        }
    }

    func resolveAndSelect(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, _ in
            guard let item = response?.mapItems.first else { return }
            selectedCategory = mapCategory(from: item.pointOfInterestCategory)
            selectedItem = item
        }
    }

    func mapCategory(from category: MKPointOfInterestCategory?) -> String {
        guard let category else { return "Sonstiges" }
        switch category {
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .nightlife: return "Bar"
        case .bakery: return "Bäckerei"
        case .park: return "Park"
        case .museum: return "Museum"
        case .store: return "Shopping"
        default: return "Sonstiges"
        }
    }
}





