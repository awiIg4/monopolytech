//
//  SellerCreateView.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import SwiftUI

/// Vue pour la création d'un nouveau vendeur
struct SellerCreateView: View {
    @StateObject private var viewModel = SellerCreateViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Créer un Vendeur")
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
                    .autocapitalization(.none)
                    
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
                }
                .padding()
                
                // Bouton de création
                Button(action: {
                    Task {
                        await viewModel.createSeller()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Image(systemName: "person.badge.plus")
                        Text("Créer le vendeur")
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
                .disabled(viewModel.isLoading || !viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1 : 0.6)
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showAlert) {
            if !viewModel.errorMessage.isEmpty {
                return Alert(
                    title: Text("Erreur"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("Succès"),
                    message: Text(viewModel.successMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationBarTitle("Créer un vendeur", displayMode: .inline)
    }
}

struct SellerCreateView_Previews: PreviewProvider {
    static var previews: some View {
        SellerCreateView()
    }
}
