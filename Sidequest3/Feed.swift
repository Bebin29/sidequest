//
//  Feed.swift
//  Sidequest3
//

import SwiftUI

// 🔹 Dummy Daten
struct FeedItem: Identifiable {
    let id = UUID()
    let username: String
}

struct Feed: View {

    let items = [
        FeedItem(username: "Anna"),
        FeedItem(username: "Tom"),
        FeedItem(username: "Mika")
    ]
    
    @State private var isSearching = false
    @State private var searchText = ""

    var filteredItems: [FeedItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {

                VStack(spacing: 20) {

                    // 🔤 HEADER (JETZT KLICKBAR)
                    HStack {
                        
                        if isSearching {
                            TextField("Profil suchen", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text("Feed")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Spacer()
                        
                        // ❌ Cancel Button bei Suche
                        if isSearching {
                            Button("Abbrechen") {
                                isSearching = false
                                searchText = ""
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation {
                            isSearching = true
                        }
                    }

                    // 📱 FEED ITEMS
                    ForEach(filteredItems) { item in
                        FeedCard(item: item)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
        }
    }
}

// 🔹 Einzelne Feed Karte
struct FeedCard: View {
    
    let item: FeedItem
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 🔝 TOP BAR
            HStack(spacing: 12) {
                
                ZStack {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 60, height: 60)
                    
                    Image("Image01")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text(formattedDate())
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 🖼️ IMAGE
            Image("IMG10")
                .resizable()
                .scaledToFill()
                .frame(height: 450)
                .clipped()
            
            // 🔽 BOTTOM BAR
            HStack {
                
                Spacer()
                
                Button(action: {
                    print("Kommentare")
                }) {
                    Image(systemName: "bubble.right.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.indigo)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                
                Button(action: {
                    print("Zur Karte")
                }) {
                    Image(systemName: "map.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.indigo)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.8), lineWidth: 3)
        )
        .shadow(radius: 5)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

#Preview {
    Home(authViewModel: AuthViewModel())
}
