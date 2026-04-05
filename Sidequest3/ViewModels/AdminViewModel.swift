//
//  AdminViewModel.swift
//  Sidequest
//

import Foundation
import os

@Observable
final class AdminViewModel {
    var users: [User] = []
    var serverStatus: ServerStatus?
    var monitoringError: String?
    var isLoading = false
    var errorMessage: String?

    private let userService = UserService()
    private let networkService = NetworkService()

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        monitoringError = nil

        async let usersTask: () = loadUsers()
        async let statusTask: () = loadServerStatus()
        _ = await (usersTask, statusTask)

        isLoading = false
    }

    func loadUsers() async {
        do {
            users = try await userService.fetchUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadServerStatus() async {
        do {
            serverStatus = try await networkService.request(
                endpoint: "api/admin/monitoring",
                method: .get
            )
            monitoringError = nil
        } catch {
            Logger(subsystem: "Sidequest", category: "Admin")
                .error("Monitoring fetch failed: \(error)")
            serverStatus = nil
            monitoringError = error.localizedDescription
        }
    }
}
