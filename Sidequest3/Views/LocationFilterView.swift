//
//  LocationFilterView.swift
//  Sidequest
//

import SwiftUI

struct LocationFilterView: View {
    @Bindable var mapViewModel: MapViewModel
    var userLatitude: Double?
    var userLongitude: Double?
    var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: LocationCategory?
    @State private var searchText: String = ""
    @State private var radiusKm: Double = 0
    @State private var useRadius: Bool = false

    private let radiusOptions: [Double] = [1, 2, 5, 10, 25, 50]

    var body: some View {
        NavigationStack {
            List {
                // Suche
                Section("Suche") {
                    TextField("Name oder Adresse", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // Kategorie
                Section("Kategorie") {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(LocationCategory.allCases, id: \.self) { category in
                                Button {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                } label: {
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == category ? Theme.accent : Theme.imagePlaceholder)
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                }

                // Umkreis
                Section("Umkreis") {
                    Toggle("Umkreissuche", isOn: $useRadius)

                    if useRadius {
                        Picker("Radius", selection: $radiusKm) {
                            ForEach(radiusOptions, id: \.self) { km in
                                Text("\(Int(km)) km").tag(km)
                            }
                        }
                        .pickerStyle(.segmented)

                        if userLatitude == nil {
                            Text("Standort nicht verfügbar")
                                .font(.caption)
                                .foregroundStyle(Theme.destructive)
                        }
                    }
                }

                // Zurücksetzen
                Section {
                    Button("Filter zurücksetzen", role: .destructive) {
                        resetFilters()
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Anwenden") {
                        applyFilters()
                        dismiss()
                        onApply()
                    }
                    .bold()
                }
            }
            .onAppear {
                // Bestehende Filter laden
                selectedCategory = mapViewModel.filter.category.flatMap { LocationCategory(rawValue: $0) }
                searchText = mapViewModel.filter.search ?? ""
                if let radius = mapViewModel.filter.radiusMeters {
                    useRadius = true
                    radiusKm = radius / 1000
                }
            }
        }
    }

    private func applyFilters() {
        mapViewModel.filter.category = selectedCategory?.rawValue
        mapViewModel.filter.search = searchText.isEmpty ? nil : searchText

        if useRadius, let lat = userLatitude, let lon = userLongitude, radiusKm > 0 {
            mapViewModel.filter.latitude = lat
            mapViewModel.filter.longitude = lon
            mapViewModel.filter.radiusMeters = radiusKm * 1000
        } else {
            mapViewModel.filter.latitude = nil
            mapViewModel.filter.longitude = nil
            mapViewModel.filter.radiusMeters = nil
        }
    }

    private func resetFilters() {
        selectedCategory = nil
        searchText = ""
        radiusKm = 1
        useRadius = false
    }
}
