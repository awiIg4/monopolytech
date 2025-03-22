//
//  GameSaleView.swift
//  monopolytech
//
//  Created by eugenio on 29/03/2025.
//

import SwiftUI

struct GameSaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GameSaleViewModel()
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case gameIds, buyerEmail, promoCode
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Titre
                    Text("Acheter des Jeux")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Formulaire d'achat
                    VStack(alignment: .leading, spacing: 15) {
                        // IDs des jeux
                        VStack(alignment: .leading) {
                            Text("IDs des jeux à acheter (séparés par virgules)")
                                .font(.headline)
                            
                            TextField("Ex: 1,2,3", text: $viewModel.gameIds)
                                .focused($focusedField, equals: .gameIds)
                                .keyboardType(.numbersAndPunctuation)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Email acheteur (optionnel)
                        VStack(alignment: .leading) {
                            Text("Email de l'acheteur (optionnel)")
                                .font(.headline)
                            
                            HStack {
                                TextField("Entrez un email", text: $viewModel.buyerEmail)
                                    .focused($focusedField, equals: .buyerEmail)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    focusedField = nil // Masquer le clavier
                                    Task {
                                        await viewModel.fetchBuyer()
                                    }
                                }) {
                                    Text("Rechercher")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Affichage acheteur trouvé
                        if let buyer = viewModel.buyer {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Acheteur trouvé:")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(buyer.nom)
                                            .font(.body).bold()
                                        Text(buyer.email)
                                            .font(.caption)
                                        if let tel = buyer.telephone {
                                            Text(tel)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Code promo
                        Toggle("J'ai un code promo", isOn: $viewModel.hasPromoCode)
                            .padding(.vertical, 5)
                        
                        if viewModel.hasPromoCode {
                            VStack(alignment: .leading) {
                                Text("Code promo")
                                    .font(.headline)
                                
                                TextField("Entrez le code", text: $viewModel.promoCode)
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
                    .padding(.horizontal)
                    
                    // Bouton d'achat
                    Button(action: {
                        focusedField = nil // Masquer le clavier
                        Task {
                            await viewModel.purchaseGames()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Image(systemName: "cart.fill.badge.plus")
                            Text("Acheter")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || viewModel.gameIds.isEmpty)
                    .opacity(viewModel.gameIds.isEmpty ? 0.6 : 1)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationBarTitle("Vente de jeux", displayMode: .inline)
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
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $viewModel.showInvoice) {
                // Vue de la facture
                InvoiceView(
                    invoiceContent: viewModel.generateInvoiceContent(),
                    onDismiss: {
                        viewModel.showInvoice = false
                        viewModel.resetForm()
                    }
                )
            }
        }
    }
}

struct InvoiceView: View {
    let invoiceContent: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Facture d'achat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text(invoiceContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        // Imprimer ou partager la facture
                        // Cette partie pourrait utiliser UIActivityViewController
                        // pour permettre le partage du texte
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Partager la facture")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    Button(action: {
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Terminer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationBarTitle("Achat réussi", displayMode: .inline)
            .navigationBarItems(trailing: Button("Fermer") {
                onDismiss()
            })
        }
    }
}

struct GameSaleView_Previews: PreviewProvider {
    static var previews: some View {
        GameSaleView()
    }
}
