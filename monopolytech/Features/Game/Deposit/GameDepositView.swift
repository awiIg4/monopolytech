//
//  GameDepositView.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import SwiftUI

// TODO: Faire disparaitre la petite barre avec OK entre la toolbar et la vue
/// Vue pour déposer des jeux
struct GameDepositView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GameDepositViewModel()
    @FocusState private var focusedField: FocusField?
    @State private var isKeyboardVisible: Bool = false
    
    enum FocusField {
        case sellerEmail, price, quantity, promoCode
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Titre
                    Text("Déposer un Jeu")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // FORMULAIRE PRINCIPAL
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Informations sur le vendeur")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        // Email du vendeur
                        VStack(alignment: .leading) {
                            Text("Email du vendeur")
                                .font(.subheadline)
                            
                            TextField("Entrez l'email du vendeur", text: $viewModel.sellerEmail)
                                .focused($focusedField, equals: .sellerEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Code promo
                        Toggle("J'ai un code promo", isOn: $viewModel.hasPromoCode)
                            .padding(.vertical, 5)
                        
                        if viewModel.hasPromoCode {
                            VStack(alignment: .leading) {
                                Text("Code promo")
                                    .font(.subheadline)
                                
                                TextField("Entrez votre code promo", text: $viewModel.promoCode)
                                    .focused($focusedField, equals: .promoCode)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.3))
                    .cornerRadius(10)
                    
                    // FORMULAIRE D'AJOUT DE JEU
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sélectionner un jeu")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        // Licence
                        VStack(alignment: .leading) {
                            Text("Licence")
                                .font(.subheadline)
                            
                            if viewModel.isLoadingLicenses {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                            } else {
                                Menu {
                                    ForEach(viewModel.licenses) { license in
                                        Button(license.nom) {
                                            viewModel.selectedLicense = license
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedLicense?.nom ?? "Sélectionner une licence")
                                            .foregroundColor(viewModel.selectedLicense == nil ? .gray : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Prix
                        VStack(alignment: .leading) {
                            Text("Prix")
                                .font(.subheadline)
                            
                            TextField("Entrez le prix", text: $viewModel.price)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Quantité
                        VStack(alignment: .leading) {
                            Text("Quantité")
                                .font(.subheadline)
                            
                            Stepper("Quantité: \(viewModel.quantity)", value: Binding(
                                get: { Int(viewModel.quantity) ?? 1 },
                                set: { viewModel.quantity = "\($0)" }
                            ), in: 1...10)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Bouton ajouter
                        Button(action: {
                            focusedField = nil
                            viewModel.addGame()
                        }) {
                            Text("Ajouter le jeu")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.3))
                    .cornerRadius(10)
                    
                    // LISTE DES JEUX À DÉPOSER
                    if !viewModel.gamesToDeposit.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Jeux sélectionnés")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            ForEach(Array(viewModel.gamesToDeposit.enumerated()), id: \.element.id) { index, game in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(game.licenseName)
                                            .fontWeight(.medium)
                                        Text("Prix: \(String(format: "%.2f", game.price)) € | Quantité: \(game.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.removeGame(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(10)
                    }
                    
                    // BOUTON SOUMETTRE
                    Button(action: {
                        focusedField = nil
                        viewModel.submitDeposit()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text("Déposer les jeux")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || viewModel.gamesToDeposit.isEmpty)
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationBarTitle("Dépôt de jeu", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isKeyboardVisible {
                        Spacer()
                        Button("OK") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            focusedField = nil
                            isKeyboardVisible = false
                        }
                    }
                }
            }
            .onAppear {
                // Surveillez les notifications de clavier
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = true
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = false
                }
            }
            .onDisappear {
                // Nettoyez les observateurs
                NotificationCenter.default.removeObserver(self)
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
                        dismissButton: .default(Text("OK")) {
                            if !viewModel.successMessage.isEmpty {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                }
            }
        }
    }
}

struct GameDepositView_Previews: PreviewProvider {
    static var previews: some View {
        GameDepositView()
    }
}
