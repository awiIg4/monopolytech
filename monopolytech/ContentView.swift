//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo
                    Image(systemName: "gamecontroller.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)
                    
                    // App Title
                    Text("MonoPolytech")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Tagline
                    Text("Plateforme de Vente de Jeux Vidéo")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Navigation Buttons
                    VStack(spacing: 15) {
                        // Game Catalog Button
                        NavigationLink(destination: HomeView()) {
                            HStack {
                                Image(systemName: "gamecontroller")
                                Text("Catalogue de Jeux")
                            }
                            .frame(minWidth: 250)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Login/Profile Button
                        if authService.isAuthenticated {
                            Button(action: {
                                authService.logout()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Se déconnecter")
                                }
                                .frame(minWidth: 250)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        } else {
                            NavigationLink(destination: LoginView()) {
                                HStack {
                                    Image(systemName: "person.circle")
                                    Text("Se Connecter")
                                }
                                .frame(minWidth: 250)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        
                        // API Test Button (for development)
                        NavigationLink(destination: APITestView()) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("Tester l'API")
                            }
                            .frame(minWidth: 250)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Footer
                    Text("© 2025 MonoPolytech")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .environmentObject(authService)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
