//
//  LocationGrid.swift
//  Sidequest
//

import SwiftUI

struct LocationGrid: View {
    let locations: [Location]
    let title: String
    let onSelect: (Location) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 6)

            if locations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("Noch keine Orte")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(locations) { location in
                        Button {
                            onSelect(location)
                        } label: {
                            locationTile(location)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Tippe um Details zu sehen")
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }

    private func locationTile(_ location: Location) -> some View {
        GeometryReader { geo in
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Theme.imagePlaceholder)
                        .overlay(ProgressView())
                }
            } else {
                Rectangle()
                    .fill(Theme.imagePlaceholder)
                    .overlay(
                        Image(systemName: "mappin")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
