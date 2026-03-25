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

    var body: some View {
        List {
            // Location Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(location.name)
                        .font(.title2.bold())
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(location.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Beschreibung
            if let description = location.description, !description.isEmpty {
                Section("Beschreibung") {
                    Text(description)
                }
            }

            // Kommentare
            Section("Kommentare (\(viewModel.comments.count))") {
                if viewModel.comments.isEmpty {
                    Text("Noch keine Kommentare")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("@\(comment.username)")
                                    .font(.caption.bold())
                                Spacer()
                                Text(comment.createdAt.prefix(10))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(comment.text)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Kommentar schreiben
            Section {
                HStack {
                    TextField("Kommentar schreiben...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        guard let userId = currentUserId, !newComment.isEmpty else { return }
                        let text = newComment
                        newComment = ""
                        Task {
                            await viewModel.addComment(locationId: location.id, userId: userId, text: text)
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(newComment.isEmpty)
                }
            }
        }
        .navigationTitle(location.name)
        .task {
            await viewModel.loadComments(locationId: location.id)
        }
    }
}
