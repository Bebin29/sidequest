//
//  LoginView.swift
//  Sidequest
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    let size = UIScreen.main.bounds.width / 3.5
    
    
    private let imageNames = [
        ["IMGSTART01", "IMGSTART02", "IMGSTART03"],
        ["IMGSTART04", "IMGSTART05", "IMGSTART06"],
        ["IMGSTART07", "IMGSTART08", "IMGSTART03"]
    ]

    var body: some View {
        NavigationStack {
            VStack {
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
                    HStack {
                        ForEach(row, id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(radius: 10)
                        }
                    }
                    .padding(.horizontal)
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
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}
