//
//  Sidequest3App.swift
//  Sidequest
//
//  Created by ole on 23.03.26.
//

import SwiftUI

@main
struct Sidequest3App: App {
    @StateObject private var container = DependencyContainer()
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                Home(authViewModel: authViewModel)
                    .environmentObject(container)
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}
