//
//  ManagerView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

struct ManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManagerViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var focusField: Field?
    
    enum Field {
        case nom, email, telephone, adresse, password
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Créer un Gestionnaire")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Formulaire
                    VStack(spacing: 15) {
                        CustomTextField(
                            text: $viewModel.nom,
                            placeholder: "Nom",
                            icon: "person.fill"
                        )
                        .focused($focusField, equals: .nom)
                        
                        CustomTextField(
                            text: $viewModel.email,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        .focused($focusField, equals: .email)
                        
                        CustomTextField(
                            text: $viewModel.telephone,
                            placeholder: "Téléphone",
                            icon: "phone.fill",
                            keyboardType: .phonePad
                        )
                        .focused($focusField, equals: .telephone)
                        
                        CustomTextField(
                            text: $viewModel.adresse,
                            placeholder: "Adresse",
                            icon: "location.fill"
                        )
                        .focused($focusField, equals: .adresse)
                        
                        // Champ mot de passe amélioré
                        CustomSecureField(
                            text: $viewModel.motdepasse,
                            placeholder: "Mot de passe",
                            icon: "lock.fill"
                        )
                        .focused($focusField, equals: .password)
                    }
                    .padding()
                    
                    // Bouton de création
                    Button(action: {
                        focusField = nil // Masquer le clavier
                        Task {
                            do {
                                print("Tentative de création du gestionnaire...")
                                let result = try await viewModel.createManager()
                                
                                // Assurons-nous que la réponse est traitée sur le thread principal
                                await MainActor.run {
                                    alertMessage = result
                                    showAlert = true
                                    print("Message de succès: \(result)")
                                    
                                    // Vidons les champs immédiatement en cas de succès
                                    if result.contains("succès") {
                                        viewModel.clearForm()
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    alertMessage = "Erreur: \(error.localizedDescription)"
                                    showAlert = true
                                    print("Erreur lors de la création: \(error)")
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Créer le gestionnaire")
                        }
                        .frame(maxWidth: .infinity)
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
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                },
                trailing: EmptyView()
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage.contains("succès") ? "Succès" : "Information"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("succès") {
                            dismiss()
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Terminé") {
                        focusField = nil
                    }
                }
            }
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

