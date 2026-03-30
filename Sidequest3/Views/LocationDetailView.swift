//
//  LocationDetailView.swift
//  Sidequest
//
//  Apple Invitations-style location detail view.
//

import SwiftUI
import MapKit

struct LocationDetailView: View {
    @State var location: Location
    var currentUserId: UUID?
    var onDelete: (() -> Void)?
    var onUpdate: ((Location) -> Void)?

    @State private var viewModel = LocationDetailViewModel()
    @State private var newComment = ""
    @State private var showFullImage = false
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var editDescription = ""
    @State private var editCategory = ""
    @State private var dominantColor: Color = .indigo
    @State private var currentImageIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    private let locationService = LocationService()

    private var isOwner: Bool {
        currentUserId == location.createdBy
    }

    private var categoryColor: Color {
        LocationCategory.color(for: location.category)
    }

    
    
    
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.06, green: 0.05, blue: 0.12)
                .ignoresSafeArea()

            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSections
                }
                .background(alignment: .bottom) {
                    // Warm tinted glass behind content, bleeding up into the hero
                    VStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: dominantColor.opacity(0.6), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)

                        Rectangle().fill(dominantColor.opacity(0.55))
                    }
                    .overlay { Rectangle().fill(.ultraThinMaterial) }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .scrollDismissesKeyboard(.immediately)

            // Floating top bar (X button + actions)
            VStack {
                floatingTopBar
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadComments(locationId: location.id)
        }
        .refreshable {
            await reloadLocation()
        }
        .fullScreenCover(isPresented: $showFullImage) {
            fullScreenImageViewer
        }
        .confirmationDialog("Location löschen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                Task {
                    do {
                        try await locationService.deleteLocation(id: location.id)
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
    }

    // MARK: - Floating Top Bar

    private var floatingTopBar: some View {
        GlassGroup {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
                .adaptiveInteractiveGlass(in: Circle())

                Spacer()

                HStack(spacing: 10) {
                    if isOwner {
                        if isEditing {
                            Button {
                                isEditing = false
                            } label: {
                                Text("Abbrechen")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            }
                            .adaptiveInteractiveGlass(in: Capsule())

                            Button {
                                Task { await saveEdit() }
                            } label: {
                                Text("Speichern")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            }
                            .adaptiveTintedGlass(dominantColor, in: Capsule())
                        } else {
                            Button {
                                editDescription = location.description ?? ""
                                editCategory = location.category
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                            }
                            .adaptiveInteractiveGlass(in: Circle())

                            Menu {
                                Button(role: .destructive) {
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                            }
                            .adaptiveInteractiveGlass(in: Circle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Hero Section (image + warm gradient + glass + title)

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            imageCarousel
                .frame(height: UIScreen.main.bounds.width * 1.15)
                .clipped()

            // Multi-layer gradient for smooth blending into content
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.3),
                    .init(color: dominantColor.opacity(0.25), location: 0.5),
                    .init(color: dominantColor.opacity(0.6), location: 0.75),
                    .init(color: dominantColor.opacity(0.9), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Additional dark scrim for text readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.6),
                    .init(color: .black.opacity(0.35), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            titleSection
        }
    }

    // MARK: - Image Carousel (with glass blur at bottom edge)

    private var imageCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(location.imageUrls.enumerated()), id: \.offset) { index, urlString in
                    Color.clear
                        .overlay {
                            if let url = URL(string: urlString) {
                                CachedAsyncImage(url: url, onLoad: { uiImage in
                                    if index == currentImageIndex {
                                        updateDominantColor(from: uiImage, cacheKey: urlString)
                                    }
                                }) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.05))
                                        .overlay {
                                            ProgressView()
                                                .tint(.white.opacity(0.3))
                                        }
                                }
                            }
                        }
                        .clipped()
                        .frame(width: UIScreen.main.bounds.width)
                        .onTapGesture { showFullImage = true }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { currentImageIndex },
            set: { if let idx = $0 { currentImageIndex = idx } }
        ))
        .onChange(of: currentImageIndex) { _, newIndex in
            guard newIndex >= 0, newIndex < location.imageUrls.count else { return }
            let urlString = location.imageUrls[newIndex]
            Task {
                if let cached = await DominantColorCache.shared.color(for: urlString) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        dominantColor = cached
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * 1.0)
        .backgroundExtensionIfAvailable()
    }

    // MARK: - Title Section (sits on glass background)

    private var titleSection: some View {
        VStack(spacing: 8) {
            if location.imageUrls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<location.imageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                    }
                }
                .padding(.bottom, 4)
            }

            Text(location.name)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)

            Text(location.category)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))

            Text(location.address)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    private func updateDominantColor(from image: UIImage, cacheKey: String) {
        Task {
            if let color = await DominantColorLoader.dominantColor(from: image, cacheKey: cacheKey) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    dominantColor = color
                }
            }
        }
    }

    // MARK: - Content Sections

    private var contentSections: some View {
        VStack(spacing: 14) {
            // Action buttons row
            actionButtons

            // Description (if exists)
            if isEditing {
                editSection
            } else if let description = location.description, !description.isEmpty {
                descriptionCard(description)
            }

            // Creator card
            creatorCard

            // Info card (details)
            infoCard

            // Comments section
            commentsCard

            // Bottom padding
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        GlassGroup(spacing: 12) {
            HStack(spacing: 12) {
                actionButton("Route", icon: "arrow.triangle.turn.up.right.diamond.fill") {
                    openInAppleMaps()
                }

                if let phone = location.phoneNumber, !phone.isEmpty {
                    actionButton("Anrufen", icon: "phone.fill") {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                actionButton("Fotos", icon: "photo.on.rectangle") {
                    showFullImage = true
                }
            }
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .adaptiveInteractiveGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Glass Card Modifier

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Description Card

    private func descriptionCard(_ text: String) -> some View {
        glassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Beschreibung")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Edit Section

    private var editSection: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bearbeiten")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Picker("Kategorie", selection: $editCategory) {
                    ForEach(LocationCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)

                TextField("Beschreibung", text: $editDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Creator Card

    @ViewBuilder
    private var creatorCard: some View {
        if let creatorUsername = location.creatorUsername {
            NavigationLink(destination: UserProfileView(userId: location.createdBy, currentUserId: currentUserId)) {
                glassCard {
                    HStack(spacing: 12) {
                        if let urlString = location.creatorProfileImageUrl,
                           let url = URL(string: urlString) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } placeholder: {
                                creatorPlaceholder(username: creatorUsername)
                            }
                            .frame(width: 40, height: 40)
                        } else {
                            creatorPlaceholder(username: creatorUsername)
                                .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Erstellt von")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(location.creatorDisplayName ?? creatorUsername)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        let hasInfo = location.priceRange != nil ||
                      location.website != nil ||
                      location.instagramHandle != nil ||
                      location.noiseLevel != nil ||
                      location.wifiAvailable == true ||
                      location.isDogFriendly == true ||
                      location.isFamilyFriendly == true

        return Group {
            if hasInfo {
                glassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Details")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if let price = location.priceRange {
                            infoRow(icon: "eurosign.circle", label: "Preis", value: price)
                        }
                        if let noise = location.noiseLevel {
                            infoRow(icon: "speaker.wave.2", label: "Lautstärke", value: noise)
                        }
                        if location.wifiAvailable == true {
                            infoRow(icon: "wifi", label: "WLAN", value: "Verfügbar")
                        }
                        if location.isDogFriendly == true {
                            infoRow(icon: "pawprint", label: "Hundefreundlich", value: "Ja")
                        }
                        if location.isFamilyFriendly == true {
                            infoRow(icon: "figure.2.and.child.holdinghands", label: "Familienfreundlich", value: "Ja")
                        }
                        if let website = location.website {
                            Button {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                infoRow(icon: "globe", label: "Website", value: website)
                            }
                            .buttonStyle(.plain)
                        }
                        if let insta = location.instagramHandle {
                            infoRow(icon: "camera", label: "Instagram", value: "@\(insta)")
                        }
                    }
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 22)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
    }

    // MARK: - Comments Card

    private var commentsCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kommentare (\(viewModel.comments.count))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if viewModel.comments.isEmpty {
                    Text("Noch keine Kommentare")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.comments) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text(String(comment.username.prefix(1)).uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("@\(comment.username)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    Text(String(comment.createdAt.prefix(10)))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                Text(comment.text)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }

                        if comment.id != viewModel.comments.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 0.5)
                        }
                    }
                }

                // Comment input
                HStack(spacing: 10) {
                    TextField("Kommentar...", text: $newComment)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
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
                            .font(.system(size: 28))
                            .foregroundStyle(newComment.isEmpty ? .white.opacity(0.2) : dominantColor)
                    }
                    .disabled(newComment.isEmpty)
                }
            }
        }
    }

    // MARK: - Full Screen Image Viewer

    private var fullScreenImageViewer: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<location.imageUrls.count, id: \.self) { index in
                        if let url = URL(string: location.imageUrls[index]) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } placeholder: {
                                ProgressView()
                                    .tint(.white.opacity(0.4))
                            }
                            .frame(width: UIScreen.main.bounds.width)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            
            .scrollTargetBehavior(.paging)

            Button {
                showFullImage = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .adaptiveInteractiveGlass(in: Circle())
            .padding()
        }
    }

    // MARK: - Helpers

    private func creatorPlaceholder(username: String) -> some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }

    func saveEdit() async {
        let body: [String: Any] = [
            "category": editCategory,
            "description": editDescription
        ]
        do {
            let updated = try await locationService.updateLocation(id: location.id, body: body)
            location = updated
            onUpdate?(updated)
            isEditing = false
        } catch {
            print("Save error: \(error)")
        }
    }

    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        ))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    func reloadLocation() async {
        do {
            let updated = try await locationService.getLocation(id: location.id)
            location = updated
            onUpdate?(updated)
        } catch {
            print("Reload failed: \(error)")
        }
    }
}

