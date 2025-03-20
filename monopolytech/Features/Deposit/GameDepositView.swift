//
//  GameDepositView.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import SwiftUI

/// View for depositing games to sell
struct GameDepositView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GameDepositViewModel()
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case price, promoCode
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.blue)
                        
                        Text("Dépôt de jeu")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Déposez vos jeux pour les vendre sur MonoPolytech")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Form
                    VStack(spacing: 20) {
                        // License picker
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Licence")
                                .font(.headline)
                            
                            if viewModel.isLoading && viewModel.licenses.isEmpty {
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
                        
                        // Price field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Prix (€)")
                                .font(.headline)
                            
                            TextField("Entrez le prix", text: $viewModel.price)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Quantity field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Quantité")
                                .font(.headline)
                            
                            Stepper("Quantité: \(viewModel.quantity)", value: Binding(
                                get: { Int(viewModel.quantity) ?? 1 },
                                set: { viewModel.quantity = "\($0)" }
                            ), in: 1...10)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Promo code field (optional)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Code promo (optionnel)")
                                .font(.headline)
                            
                            TextField("Entrez un code promo", text: $viewModel.promoCode)
                                .focused($focusedField, equals: .promoCode)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Submit button
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
                                Text("Déposer le jeu")
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
            .navigationTitle("Dépôt de jeu")
            .navigationBarTitleDisplayMode(.inline)
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
                    Spacer()
                    Button("OK") {
                        focusedField = nil
                    }
                }
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
