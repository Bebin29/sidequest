//
//  PostPreviewView.swift
//  Sidequest
//

import SwiftUI

struct PostPreviewView: View {
    let name: String
    let address: String
    let category: String
    let description: String
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Bild 1:1
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                            .clipped()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(name)
                                .font(.title.bold())

                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(category)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }

                        // Beschreibung
                        if !description.isEmpty {
                            Divider()
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Vorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
