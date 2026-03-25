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
    let images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !images.isEmpty {
                        ZStack(alignment: .bottom) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 0) {
                                    ForEach(0..<images.count, id: \.self) { index in
                                        Image(uiImage: images[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                            .clipped()
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.paging)
                            .scrollPosition(id: Binding(
                                get: { currentPage },
                                set: { if let page = $0 { currentPage = page } }
                            ))
                            .frame(height: UIScreen.main.bounds.width)

                            if images.count > 1 {
                                HStack(spacing: 6) {
                                    ForEach(0..<images.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                                            .frame(width: 7, height: 7)
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
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
