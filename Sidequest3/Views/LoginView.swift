//
//  LoginView.swift
//  Sidequest
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    let size = UIScreen.main.bounds.width / 3.5
    
    var body: some View {
        NavigationStack {
            ZStack {
                //Color.white
                    //.ignoresSafeArea()
                
               
                  
                      VStack {
                          Text("Sidequest")
                              .font(.title)
                              .fontWeight(.bold)
                              .foregroundColor(Color(.systemIndigo))
                          Text("Entdecke und teile Orte mit Freunden")
                              .font(.headline)
                              .fontWeight(.bold)
                              .foregroundColor(Color(.systemIndigo))
                          Spacer()
                          
                          HStack {
                              Image("IMGSTART01")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.top)
                              Image("IMGSTART02")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.top)
                              Image("IMGSTART03")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.top)
                          }
                          .padding(.horizontal)
                          HStack {
                              Image("IMGSTART04")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                              Image("IMGSTART05")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  
                              Image("IMGSTART06")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  
                          }
                          .padding(.horizontal)
                          HStack {
                              Image("IMGSTART07")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.bottom)
                              Image("IMGSTART08")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.bottom)
                              Image("IMGSTART09")
                                  .resizable()
                                  .scaledToFill()
                                  .frame(width: size, height: size)
                                  .cornerRadius(20)
                                  .padding(.bottom)
                          }
                          .padding(.horizontal)
                          
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
                                  .foregroundStyle(.red)
                          }
                          /*NavigationLink() {
                              Text("Registrieren")
                                  .frame(maxWidth: .infinity)
                                  .padding()
                                  .background(Color.colorText)
                                  .foregroundColor(.colorHintergrund)
                                  .cornerRadius(20)
                                  .fontWeight(.semibold)

                          }
                          .padding(.horizontal)
                          
                          NavigationLink(destination: LoginView()) {
                              Text("Anmelden")
                                  .frame(maxWidth: .infinity)
                                  .padding()
                                  .background(Color.colorText)
                                  .foregroundColor(.colorHintergrund)
                                  .cornerRadius(20)
                                  .fontWeight(.semibold)

                          }
                          .padding(.horizontal)
                           
*/
                          Spacer()
                      }
                      .padding()
                }
            

        }
        
     
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}
