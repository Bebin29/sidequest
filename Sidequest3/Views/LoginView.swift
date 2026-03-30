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
                            if #available(iOS 26.0, *) {
                                HStack {
                                    
                                    
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART01")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART02")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART03")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    
                                    
                                    
                                        
                                            
                                   
                                    
                                }
                                .padding(.horizontal)
                                HStack {
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART04")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART05")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART06")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                        
                                }
                                .padding(.horizontal)
                                HStack {
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART07")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART08")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                    VStack {
                                        ZStack {
                                            Image("IMGSTART03")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: size, height: size)
                                                .clipped()
                                                .cornerRadius(25)
                                        }
                                        .frame(width: size, height: size)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                            // Fallback on earlier versions
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
