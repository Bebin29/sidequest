//
//  AdminViewModel.swift
//  Sidequest
//

import Foundation
import os

@Observable
final class AdminViewModel {
    var dashboard: DashboardData?
    var isLoading = false
    var errorMessage: String?

    private let networkService = NetworkService()

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            dashboard = try await networkService.request(
                endpoint: "api/admin/dashboard",
                method: .get
            )
        } catch {
            Logger(subsystem: "Sidequest", category: "Admin")
                .error("Dashboard fetch failed: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
