//
//  LocationDetailView.swift
//  Sidequest
//

import SwiftUI

struct LocationDetailView: View {
    let location: Location
    var currentUserId: UUID?
    var onDelete: (() -> Void)?

    @State private var viewModel = LocationDetailViewModel()
    @State private var newComment = ""
    @State private var showFullImage = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    private var isOwner: Bool {
        currentUserId == location.createdBy
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Bilder Carousel
                if !location.imageUrls.isEmpty {
                    ImageCarouselRemote(
                        urls: location.imageUrls,
                        onTap: { showFullImage = true }
                    )
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
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Location löschen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                Task {
                    do {
                        try await LocationService().deleteLocation(id: location.id)
                        onDelete?()
                        dismiss()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text("Diese Location wird unwiderruflich gelöscht.")
        }
        .sheet(isPresented: $showEditSheet) {
            EditLocationView(location: location) { updatedLocation in
                showEditSheet = false
            }
        }
        .task {
            await viewModel.loadComments(locationId: location.id)
        }
        .fullScreenCover(isPresented: $showFullImage) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<location.imageUrls.count, id: \.self) { index in
                            AsyncImage(url: URL(string: location.imageUrls[index])) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: UIScreen.main.bounds.width)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
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

// Remote Bilder Carousel (URLs)
struct ImageCarouselRemote: View {
    let urls: [String]
    var onTap: () -> Void = {}
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<urls.count, id: \.self) { index in
                        AsyncImage(url: URL(string: urls[index])) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                    .clipped()
                                    .onTapGesture { onTap() }
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                    .background(Color(.systemGray6))
                            case .empty:
                                ProgressView()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding(
                get: { currentPage },
                set: { if let v = $0 { currentPage = v } }
            ))
            .frame(height: UIScreen.main.bounds.width)

            if urls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<urls.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}
