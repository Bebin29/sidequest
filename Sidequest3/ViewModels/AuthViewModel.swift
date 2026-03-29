//
//  AuthViewModel.swift
//  Sidequest
//

import Foundation
import AuthenticationServices

@Observable
final class AuthViewModel {
    var currentUser: User?
    var isAuthenticated = false
    var needsOnboarding = false
    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService()

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            let appleUserId = credential.user
            let email = credential.email
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let displayName = fullName.isEmpty ? nil : fullName

            // Apple User ID lokal speichern
            UserDefaults.standard.set(appleUserId, forKey: "appleUserId")

            Task {
                await signIn(appleUserId: appleUserId, email: email, displayName: displayName)
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signIn(appleUserId: String, email: String?, displayName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let (user, _) = try await authService.signInWithApple(
                appleUserId: appleUserId,
                email: email,
                displayName: displayName
            )
            currentUser = user
            isAuthenticated = true
            // Username wird vom Backend automatisch aus der E-Mail generiert
            // User kann ihn später auf der Profilseite ändern
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func checkExistingSession() async {
        guard let appleUserId = UserDefaults.standard.string(forKey: "appleUserId") else { return }
        await signIn(appleUserId: appleUserId, email: nil, displayName: nil)
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        currentUser = nil
        isAuthenticated = false
    }
}
