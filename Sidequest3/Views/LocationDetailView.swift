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

    private var imageHeight: CGFloat {
        UIScreen.main.bounds.width * 1.15
    }

    var body: some View {
        ZStack {
            // Warm base — material picks up this color
            dominantColor.opacity(0.85)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: dominantColor.description)

            ScrollView {
                ZStack(alignment: .top) {
                    // Layer 1: Image at top (stretches on top overscroll)
                    GeometryReader { geo in
                        let offset = geo.frame(in: .named("scroll")).minY
                        let stretch = max(0, offset)

                        imageCarousel
                            .frame(width: geo.size.width, height: imageHeight + stretch)
                            .offset(y: -stretch)
                    }
                    .frame(height: imageHeight)

                    // Layer 2: Gradient over image (stretches with image)
                    GeometryReader { geo in
                        let offset = geo.frame(in: .named("scroll")).minY
                        let stretch = max(0, offset)

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.25),
                                .init(color: dominantColor.opacity(0.3), location: 0.5),
                                .init(color: dominantColor.opacity(0.75), location: 0.8),
                                .init(color: dominantColor.opacity(0.95), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: imageHeight + stretch)
                        .offset(y: -stretch)
                        .allowsHitTesting(false)
                    }
                    .frame(height: imageHeight)

                    // Layer 3: Content with material background
                    VStack(spacing: 0) {
                        Spacer().frame(height: imageHeight - 100)

                        VStack(spacing: 0) {
                            titleSection
                            contentSections
                            Spacer().frame(height: 40)
                        }
                        .background(alignment: .top) {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .mask {
                                    VStack(spacing: 0) {
                                        LinearGradient(
                                            colors: [.clear, .black],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 120)
                                        Color.black
                                        LinearGradient(
                                            colors: [.black, .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 120)
                                    }
                                }
                        }
                    }
                }
                
            }
            .coordinateSpace(name: "scroll")
            .scrollDismissesKeyboard(.immediately)
            

            VStack {
                floatingTopBar
                Spacer()
            }
        }
    
        .navigationBarHidden(true)
        .task {
            await viewModel.loadComments(locationId: location.id)
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
                         .font(.subheadline).fontWeight(.bold)
                         .foregroundStyle(.white)
                         .frame(width: 44, height: 44)
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
                                    .font(.subheadline).fontWeight(.semibold).fontDesign(.rounded)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(height: 44)
                            }
                            .adaptiveInteractiveGlass(in: Capsule())

                            Button {
                                Task { await saveEdit() }
                            } label: {
                                Text("Speichern")
                                    .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(height: 44)
                            }
                            .adaptiveTintedGlass(dominantColor, in: Capsule())
                        } else {
                            Button {
                                editDescription = location.description ?? ""
                                editCategory = location.category
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                            }
                            .adaptiveInteractiveGlass(in: Circle())

                            
                            
                            
                           
                            
                            
                            
                            
                            
                            Menu {
                                Button(role: .destructive) {
                                    showDeleteConfirm = true
                                } label: {
                                    Text("Löschen")
                                        .foregroundStyle(Color(.red))
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
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

    // MARK: - Image Carousel

    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
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
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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
                .font(.largeTitle).fontWeight(.bold).fontDesign(.rounded)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)

            Text(location.category)
                .font(.subheadline).fontWeight(.medium).fontDesign(.rounded)
                .foregroundStyle(.white.opacity(0.65))

            Text(location.address)
                .font(.subheadline).fontWeight(.medium).fontDesign(.rounded)
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

                actionButton("Teilen", icon: "square.and.arrow.up") {
                    shareLocation()
                }
            }
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2).fontWeight(.medium)
                Text(title)
                    .font(.subheadline).fontWeight(.semibold).fontDesign(.rounded)
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
                    .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text(text)
                    .font(.subheadline).fontWeight(.regular).fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Edit Section

    private var editSection: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bearbeiten")
                    .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
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
                    .font(.subheadline).fontDesign(.rounded)
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
                                .font(.caption).fontWeight(.medium).fontDesign(.rounded)
                                .foregroundStyle(.white.opacity(0.5))
                            Text(location.creatorDisplayName ?? creatorUsername)
                                .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote).fontWeight(.semibold)
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
                            .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
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
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 22)
            Text(label)
                .font(.footnote).fontWeight(.medium).fontDesign(.rounded)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.footnote).fontWeight(.semibold).fontDesign(.rounded)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
    }

    // MARK: - Comments Card

    private var commentsCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kommentare (\(viewModel.comments.count))")
                    .font(.subheadline).fontWeight(.bold).fontDesign(.rounded)
                    .foregroundStyle(.white)

                if viewModel.comments.isEmpty {
                    Text("Noch keine Kommentare")
                        .font(.subheadline).fontWeight(.medium).fontDesign(.rounded)
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
                                        .font(.caption).fontWeight(.bold).fontDesign(.rounded)
                                        .foregroundStyle(.white.opacity(0.6))
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("@\(comment.username)")
                                        .font(.footnote).fontWeight(.bold).fontDesign(.rounded)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    Text(String(comment.createdAt.prefix(10)))
                                        .font(.caption).fontWeight(.medium).fontDesign(.rounded)
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                Text(comment.text)
                                    .font(.footnote).fontWeight(.regular).fontDesign(.rounded)
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
                        .font(.subheadline).fontDesign(.rounded)
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
                            .font(.title)
                            .foregroundStyle(newComment.isEmpty ? .white.opacity(0.2) : dominantColor)
                    }
                    .disabled(newComment.isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers

    private func shareLocation() {
        let text = "\(location.name)\n\(location.address)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            var topController = root
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityVC, animated: true)
        }
    }

    private func creatorPlaceholder(username: String) -> some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(.footnote).fontWeight(.bold).fontDesign(.rounded)
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

