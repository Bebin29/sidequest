//
//  BackgroundExtensionIfAvailable.swift
//  Sidequest
//
//  Availability wrapper for .backgroundExtensionEffect() (iOS 26+).
//  On Xcode 26: Add XCODE_26 to Build Settings → Swift Compiler → Active Compilation Conditions.
//

import SwiftUI

extension View {
    @ViewBuilder
    func backgroundExtensionIfAvailable() -> some View {
        #if XCODE_26
        if #available(iOS 26, *) {
            self.backgroundExtensionEffect()
        } else {
            self.ignoresSafeArea(.container, edges: .top)
        }
        #else
        self.ignoresSafeArea(.container, edges: .top)
        #endif
    }
}
