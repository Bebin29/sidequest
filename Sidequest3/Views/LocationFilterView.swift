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
    @State private var minRating: Double = 0
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
                    ScrollView(.horizontal, showsIndicators: false) {
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
                                        .background(selectedCategory == category ? Color.indigo : Color(.systemGray5))
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Mindestbewertung
                Section("Mindestbewertung") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: Double(star) <= minRating ? "star.fill" : "star")
                                .foregroundStyle(Double(star) <= minRating ? .yellow : .gray)
                                .font(.title3)
                                .onTapGesture {
                                    if minRating == Double(star) {
                                        minRating = 0
                                    } else {
                                        minRating = Double(star)
                                    }
                                }
                        }
                        Spacer()
                        if minRating > 0 {
                            Text("ab \(Int(minRating)) Sterne")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                                .foregroundStyle(.red)
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
                selectedCategory = mapViewModel.filter.category
                minRating = mapViewModel.filter.minRating ?? 0
                searchText = mapViewModel.filter.search ?? ""
                if let radius = mapViewModel.filter.radiusMeters {
                    useRadius = true
                    radiusKm = radius / 1000
                }
            }
        }
    }

    private func applyFilters() {
        mapViewModel.filter.category = selectedCategory
        mapViewModel.filter.minRating = minRating > 0 ? minRating : nil
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
        minRating = 0
        searchText = ""
        radiusKm = 1
        useRadius = false
    }
}
