//
//  HomeView.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showLogoutAlert = false  // Pour contrôler l'affichage de l'alerte
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 40)
                
                // Logo et Titre avec animation
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                        .rotation3DEffect(.degrees(3), axis: (x: 0, y: 1, z: 0))
                    
                    Text("MonoPolytech")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Votre Marketplace de Jeux Vidéo")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Description avec nouveau design
                VStack(spacing: 15) {
                    Text("Bienvenue sur MonoPolytech")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Découvrez notre sélection de jeux vidéo à des prix étudiants. Vendez vos jeux facilement et rejoignez notre communauté de gamers.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
                .padding(.horizontal)
                
                // Boutons de navigation avec nouveau style
                VStack(spacing: 15) {
                    // About Button
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("À propos")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 250)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                    }
                    
                    // API Test Button
                    NavigationLink(destination: APITestView()) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                            Text("Tester l'API")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 250)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.3), radius: 5)
                    }
                    
                    // Logout Button
                    if authService.isAuthenticated {
                        Button(action: {
                            showLogoutAlert = true  // Afficher l'alerte au lieu de se déconnecter directement
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                Text("Déconnexion")
                                    .fontWeight(.semibold)
                            }
                            .frame(minWidth: 250)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .red.opacity(0.3), radius: 5)
                        }
                    }
                    
                    // TempLogin Button - Nouveau bouton
                    Button(action: {
                        // D'abord déconnexion si déjà connecté
                        if authService.isAuthenticated {
                            authService.logout()
                        }
                        
                        // Puis connexion en tant qu'admin
                        Task {
                            do {
                                try await authService.login(email: "admin@example.com", password: "admin123", userType: "admin")
                            } catch {
                                print("Erreur de connexion temporaire: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill.badge.plus")
                            Text("TempLogin (Admin)")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 250)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .purple.opacity(0.3), radius: 5)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Footer amélioré
                VStack(spacing: 8) {
                    Text("© 2025 MonoPolytech")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Fait avec")
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("par des étudiants de Polytech")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    .white,
                    Color.blue.opacity(0.1),
                    Color.blue.opacity(0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarHidden(true)
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Confirmation"),
                message: Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
                primaryButton: .destructive(Text("Déconnexion")) {
                    authService.logout()
                },
                secondaryButton: .cancel(Text("Annuler"))
            )
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Image(systemName: "building.columns.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 30)
                
                Text("À propos de MonoPolytech")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 20) {
                    InfoSection(
                        title: "Notre Histoire",
                        content: "MonoPolytech est né de la vision d'étudiants de Polytech passionnés par les jeux vidéo et désireux de créer une plateforme d'échange accessible à tous."
                    )
                    
                    InfoSection(
                        title: "Notre Mission",
                        content: "Faciliter l'accès aux jeux vidéo pour les étudiants en proposant une plateforme simple, sécurisée et économique."
                    )
                    
                    InfoSection(
                        title: "Nos Valeurs",
                        content: "• Accessibilité\n• Transparence\n• Communauté\n• Innovation"
                    )
                }
                .padding(.horizontal)
                
                Text("Rejoignez notre communauté grandissante !")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top)
            }
            .padding()
        }
        .background(Color.white)
        .navigationBarTitle("À propos", displayMode: .inline)
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(content)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
