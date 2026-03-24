//
//  AdminViewModel.swift
//  Sidequest
//

import Foundation

@Observable
final class AdminViewModel {
    var users: [User] = []
    var isLoading = false
    var errorMessage: String?

    private let userService = UserService()

    func loadUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await userService.fetchUsers()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
