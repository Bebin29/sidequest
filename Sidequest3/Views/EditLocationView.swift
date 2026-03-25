//
//  EditLocationView.swift
//  Sidequest
//

import SwiftUI

struct EditLocationView: View {
    let location: Location
    var onSave: (Location) -> Void

    @State private var description: String
    @State private var category: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let locationService = LocationService()

    init(location: Location, onSave: @escaping (Location) -> Void) {
        self.location = location
        self.onSave = onSave
        _description = State(initialValue: location.description ?? "")
        _category = State(initialValue: location.category)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    Text(location.name)
                        .foregroundStyle(.secondary)
                }

                Section("Kategorie") {
                    Picker("Kategorie", selection: $category) {
                        ForEach(["Restaurant", "Café", "Bar", "Club", "Bäckerei", "Fast Food",
                                 "Eisdiele", "Park", "Museum", "Shopping", "Aussichtspunkt",
                                 "Strand", "Sonstiges"], id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Beschreibung") {
                    TextField("Beschreibung", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .bold()
                    .disabled(isSaving)
                }
            }
        }
    }

    func save() async {
        isSaving = true
        errorMessage = nil

        var body: [String: Any] = [
            "category": category,
            "description": description
        ]

        do {
            let updated = try await locationService.updateLocation(id: location.id, body: body)
            onSave(updated)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
