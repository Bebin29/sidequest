//
//  LocationDetailView.swift
//  Sidequest
//

import SwiftUI

struct LocationDetailView: View {
    let location: Location
    var currentUserId: UUID?

    @State private var viewModel = LocationDetailViewModel()
    @State private var newComment = ""
    @State private var showFullImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image
                if let firstUrl = location.imageUrls.first, let url = URL(string: firstUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 220)
                                .clipped()
                                .onTapGesture { showFullImage = true }
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .background(Color(.systemGray6))
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 150)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(location.name)
                            .font(.title.bold())

                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(location.category)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    // Weitere Bilder (falls mehr als 1)
                    if location.imageUrls.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(location.imageUrls.dropFirst()), id: \.self) { urlString in
                                    AsyncImage(url: URL(string: urlString)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 140, height: 140)
                                            .overlay(ProgressView())
                                    }
                                }
                            }
                        }
                    }

                    // Beschreibung
                    if let description = location.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Beschreibung")
                                .font(.headline)
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Kommentare
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kommentare (\(viewModel.comments.count))")
                            .font(.headline)

                        if viewModel.comments.isEmpty {
                            Text("Noch keine Kommentare")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.comments) { comment in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(String(comment.username.prefix(1)).uppercased())
                                                .font(.caption.bold())
                                                .foregroundStyle(.secondary)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text("@\(comment.username)")
                                                .font(.subheadline.bold())
                                            Spacer()
                                            Text(String(comment.createdAt.prefix(10)))
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        Text(comment.text)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)

                                if comment.id != viewModel.comments.last?.id {
                                    Divider()
                                }
                            }
                        }

                        // Kommentar schreiben
                        HStack(spacing: 10) {
                            TextField("Kommentar schreiben...", text: $newComment)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())

                            Button {
                                guard let userId = currentUserId, !newComment.isEmpty else { return }
                                let text = newComment
                                newComment = ""
                                Task {
                                    await viewModel.addComment(locationId: location.id, userId: userId, text: text)
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                            .disabled(newComment.isEmpty)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments(locationId: location.id)
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let firstUrl = location.imageUrls.first, let url = URL(string: firstUrl) {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } placeholder: {
                        ProgressView()
                    }
                    Button {
                        showFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
            }
        }
    }
}
