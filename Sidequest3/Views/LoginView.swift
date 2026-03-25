//
//  LoginView.swift
//  Sidequest
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Sidequest")
                .font(.largeTitle.bold())

            Text("Entdecke und teile Orte mit Freunden")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if authViewModel.isLoading {
                ProgressView()
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    authViewModel.handleAppleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 40)
            }

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }
}
