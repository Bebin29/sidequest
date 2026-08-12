//
//  LoginView.swift
//  Sidequest
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel


    private let imageNames = [
        ["IMGSTART01", "IMGSTART02", "IMGSTART03"],
        ["IMGSTART04", "IMGSTART05", "IMGSTART06"],
        ["IMGSTART07", "IMGSTART08", "IMGSTART03"]
    ]

    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 16
            let spacing: CGFloat = 12
            let size = (geometry.size.width - padding * 2 - spacing * 2) / 3

            VStack(spacing: spacing) {
                Text("Sidequest")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)
                Text("Entdecke und teile Orte mit Freunden")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)

                Spacer()

                ForEach(imageNames, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(radius: 10)
                                .accessibilityHidden(true)
                        }
                    }
                }

                Spacer()

                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        authViewModel.handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 50)
                    .padding(.horizontal)
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.destructive)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}
