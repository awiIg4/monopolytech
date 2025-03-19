//
//  LoginView.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // En-tête
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Connexion")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connectez-vous à votre compte MonoPolytech")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                // Formulaire
                VStack(spacing: 20) {
                    // Type d'utilisateur - comme dans le web (seulement admin et gestionnaire)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Type d'utilisateur")
                            .font(.headline)
                        
                        Picker("Sélectionnez votre type", selection: $viewModel.userType) {
                            Text("Administrateur").tag("admin")
                            Text("Gestionnaire").tag("gestionnaire")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    
                    // Champ Email
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.headline)
                        
                        TextField("Entrez votre email", text: $viewModel.email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                    }
                    
                    // Champ Mot de passe
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Mot de passe")
                            .font(.headline)
                        
                        SecureField("Entrez votre mot de passe", text: $viewModel.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Message d'erreur
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 5)
                    }
                    
                    // Bouton de connexion
                    Button(action: {
                        Task {
                            await viewModel.login()
                            if viewModel.isAuthenticated || authService.isAuthenticated {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text("Se connecter")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationTitle("Connexion")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView()
        }
    }
}
