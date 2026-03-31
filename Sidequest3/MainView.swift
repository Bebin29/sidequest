//
//  MainView.swift
//  Sidequest3
//
//  Created by ole on 29.03.26.
//

import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @Bindable var authViewModel: AuthViewModel
    var userId: UUID?
    var currentUserId: UUID?
    var mapViewModel: MapViewModel
    var onShowOnMap: ((Location) -> Void)?
    @State private var viewModel = FeedViewModel()
    @State private var selectedLocation: Location?
    @State private var scrolledId: UUID?
    @State private var hasAppeared = false
    @State private var showSearchSheet = false
    @State private var showCardDetailViewSheet = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Adaptive background color — falls back to category color
    private var dominantColor: Color {
        if let color = viewModel.currentDominantColor {
            return color
        }
        guard viewModel.currentIndex >= 0,
              viewModel.currentIndex < viewModel.locations.count else {
            return .indigo
        }
        return categoryColor(for: viewModel.locations[viewModel.currentIndex].category)
    }


    
    var body: some View {
        ZStack {
            // Adaptive background — fills entire screen
            adaptiveBackground
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Header
                header

                // Main carousel area
                if viewModel.isLoading && viewModel.locations.isEmpty {
                    Spacer()
                    skeletonView
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.locations.isEmpty {
                    Spacer()
                    errorState(message: error)
                    Spacer()
                } else if viewModel.locations.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    // Carousel — positioned close to header with bottom flex
                    Spacer().frame(height: 8)
                    carousel
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 30)
                        .onAppear {
                            guard !hasAppeared else { return }
                            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                                hasAppeared = true
                            }
                        }
                    Spacer()
                }
            }
        }
        .task {
            guard let userId else { return }
            await viewModel.loadFeed(userId: userId)
        }
        .onChange(of: scrolledId) { _, newId in
            guard let newId else { return }
            if let index = viewModel.locations.firstIndex(where: { $0.id == newId }) {
                if index != viewModel.currentIndex {
                    viewModel.currentIndex = index
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                // Pagination: load more when near the end
                if index >= viewModel.locations.count - 2 {
                    guard let userId else { return }
                    Task { await viewModel.loadMore(userId: userId) }
                }
            }
        }
        /*
         .sheet(item: $selectedLocation) { location in
             NavigationStack {
                 CardDetailView(location: location, currentUserId: currentUserId, providedDominantColor: viewModel.dominantColors[location.id], onTap: {})
             }
         }
         */
        
        
        
        .sheet(item: $selectedLocation) { location in
            NavigationStack {
                LocationDetailView(location: location, currentUserId: currentUserId)
            }
        }

        

    }
    private var header: some View {
        HStack {
            Text("Home")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .sheet(isPresented: $showSearchSheet) {
                PlaceSearchView(mapViewModel: mapViewModel, userId: userId) {
                    showSearchSheet = false
                }
            }

            Button {
                showSettings = true
            } label: {
                if let user = authViewModel.currentUser {
                    if let urlString = user.profileImageUrl,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.indigo)
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(authViewModel: authViewModel)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Carousel

    /// Apple-Docs-Pattern: ScrollView + LazyHStack + scrollTargetLayout + viewAligned
    /// Fixed 2:3 aspect ratio for cards (portrait, like Apple Invitations).
    private var carousel: some View {
        let cardWidth = UIScreen.main.bounds.width - 56
        let imageHeight = cardWidth * 4.0 / 3.0  // 3:4 aspect ratio for image
        let glassHeight: CGFloat = 140            // warm glass panel below image
        let cardHeight = imageHeight + glassHeight

        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(viewModel.locations) { location in
                    FeedCarouselCard(
                        location: location,
                        borderColor: viewModel.dominantColors[location.id] ?? categoryColor(for: location.category),
                        onTap: { selectedLocation = location },
                        onImageLoaded: { image in
                            handleImageLoaded(image, for: location)
                        }
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .onAppear {
                        if location.id == viewModel.locations.last?.id {
                            guard let userId else { return }
                            Task { await viewModel.loadMore(userId: userId) }
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    loadingMoreCard
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledId)
        .contentMargins(.horizontal, 28, for: .scrollContent)
    }

    // MARK: - Adaptive Background

    private var adaptiveBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.12)

            RadialGradient(
                colors: [
                    dominantColor.opacity(0.65),
                    dominantColor.opacity(0.35),
                    .clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 800
            )
        }
        .animation(.easeInOut(duration: 0.5), value: dominantColor.description)
    }

    // MARK: - Image Loaded Handler

    private func handleImageLoaded(_ image: UIImage, for location: Location) {
        guard let urlString = location.imageUrls.first else { return }
        Task {
            if let color = await DominantColorLoader.dominantColor(from: image, cacheKey: urlString) {
                viewModel.setDominantColor(color, for: location.id)
            }
        }
    }

    // MARK: - Category Colors

    private func categoryColor(for category: String) -> Color {
        LocationCategory.color(for: category)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("Noch nichts im Feed")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Füge Freunde hinzu, um ihre Spots zu sehen.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("Laden fehlgeschlagen")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                guard let userId else { return }
                Task { await viewModel.loadFeed(userId: userId) }
            } label: {
                Text("Erneut versuchen")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 11)
                    //.liquidGlassPill()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonView: some View {
        let cardWidth = UIScreen.main.bounds.width - 56
        let imageHeight = cardWidth * 4.0 / 3.0
        let cardHeight = imageHeight + 140

        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCarouselCard()
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 28, for: .scrollContent)
    }

    // MARK: - Loading More Card

    private var loadingMoreCard: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.04))
            .overlay {
                ProgressView()
                    .tint(.white.opacity(0.4))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
            }
    }
}

