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

    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(container)
        }
    }
}
