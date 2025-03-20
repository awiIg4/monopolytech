//
//  ManagerView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

struct ManagerView: View {
    @StateObject private var viewModel = ManagerViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Créer un Gestionnaire")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                // Formulaire
                VStack(spacing: 15) {
                    CustomTextField(
                        text: $viewModel.nom,
                        placeholder: "Nom",
                        icon: "person.fill"
                    )
                    
                    CustomTextField(
                        text: $viewModel.email,
                        placeholder: "Email",
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )
                    
                    CustomTextField(
                        text: $viewModel.telephone,
                        placeholder: "Téléphone",
                        icon: "phone.fill",
                        keyboardType: .phonePad
                    )
                    
                    CustomTextField(
                        text: $viewModel.adresse,
                        placeholder: "Adresse",
                        icon: "location.fill"
                    )
                    
                    // Champ mot de passe amélioré
                    CustomSecureField(
                        text: $viewModel.motdepasse,
                        placeholder: "Mot de passe",
                        icon: "lock.fill"
                    )
                }
                .padding()
                
                // Bouton de création
                Button(action: {
                    Task {
                        do {
                            try await viewModel.createManager()
                            alertMessage = "Gestionnaire créé avec succès"
                            showAlert = true
                            viewModel.clearForm()
                        } catch {
                            alertMessage = "Erreur: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Créer le gestionnaire")
                    }
                    .frame(minWidth: 200)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1 : 0.6)
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Aide à éviter les conflits de contraintes
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Information"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            SecureField(placeholder, text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

