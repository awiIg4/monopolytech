//
//  SellerStatsView.swift
//  monopolytech
//
//  Created by eugenio on 24/03/2025.
//

import SwiftUI

/// Vue pour afficher et gérer les statistiques d'un vendeur
struct SellerStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SellerStatsViewModel()
    @FocusState private var focusedField: FocusField?
    
    /// Champs pouvant recevoir le focus
    enum FocusField {
        case sellerEmail
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Titre
                    Text("Statistiques de Vendeur")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Formulaire de recherche
                    VStack(alignment: .leading, spacing: 15) {
                        // Email du vendeur
                        VStack(alignment: .leading) {
                            Text("Email du vendeur")
                                .font(.headline)
                            
                            HStack {
                                TextField("Entrez l'email du vendeur", text: $viewModel.sellerEmail)
                                    .focused($focusedField, equals: .sellerEmail)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    focusedField = nil
                                    viewModel.searchSeller()
                                }) {
                                    Text("Rechercher")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(viewModel.sellerEmail.isEmpty || viewModel.isLoading)
                            }
                        }
                        
                        // Sélection de session
                        VStack(alignment: .leading) {
                            Text("Session")
                                .font(.headline)
                            
                            if viewModel.isLoadingSessions {
                                ProgressView("Chargement des sessions...")
                                    .padding()
                            } else if viewModel.sessions.isEmpty {
                                Text("Aucune session disponible")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                Picker("Sélectionnez une session", selection: $viewModel.selectedSessionId) {
                                    ForEach(viewModel.sessions, id: \.id) { session in
                                        if let id = session.id {
                                            Text("Session #\(id) (\(viewModel.formatDate(session.date_debut)) - \(viewModel.formatDate(session.date_fin)))")
                                                .tag(String(id))
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Bouton pour charger les statistiques
                        Button(action: {
                            viewModel.loadSellerStats()
                        }) {
                            HStack {
                                if viewModel.isLoadingStats {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                }
                                Image(systemName: "chart.bar.fill")
                                Text("Charger les statistiques")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.seller == nil || viewModel.selectedSessionId.isEmpty || viewModel.isLoadingStats)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.3))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Affichage du vendeur
                    if let seller = viewModel.seller {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Informations Vendeur")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Group {
                                Text("Nom: \(seller.nom)")
                                Text("Email: \(seller.email)")
                                Text("Téléphone: \(seller.telephone)")
                                if let adresse = seller.adresse, !adresse.isEmpty {
                                    Text("Adresse: \(adresse)")
                                }
                            }
                            .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Statistiques globales (toutes sessions)
                    if viewModel.stats != .empty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Statistiques Globales (Toutes Sessions)")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Group {
                                StatRow(title: "Revenu total généré", value: String(format: "%.2f €", viewModel.stats.totalRevenueAllSessions), icon: "dollarsign.circle.fill")
                                
                                StatRow(title: "Somme totale due", value: String(format: "%.2f €", viewModel.stats.totalAmountDue), icon: "creditcard.fill")
                            }
                            .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Statistiques pour la session sélectionnée
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Statistiques pour la Session Sélectionnée")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Group {
                                StatRow(title: "Jeux vendus", value: "\(viewModel.stats.totalSoldGames)", icon: "bag.fill")
                                StatRow(title: "Jeux en stock", value: "\(viewModel.stats.stockGames.count)", icon: "shippingbox.fill")
                                StatRow(title: "Jeux à récupérer", value: "\(viewModel.stats.recuperableGames.count)", icon: "arrow.down.circle.fill")
                                StatRow(title: "Somme due", value: String(format: "%.2f €", viewModel.stats.amountDue), icon: "banknote.fill")
                                StatRow(title: "Revenu généré", value: String(format: "%.2f €", viewModel.stats.totalRevenue), icon: "chart.line.uptrend.xyaxis")
                            }
                            .font(.body)
                            
                            // Bouton pour réinitialiser le solde
                            Button(action: {
                                viewModel.resetSellerBalance()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Réinitialiser le solde")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding(.top)
                            .disabled(viewModel.isLoading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Liste des jeux à récupérer
                        if !viewModel.stats.recuperableGames.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Jeux à Récupérer")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                
                                ForEach(viewModel.stats.recuperableGames, id: \.id) { game in
                                    if let gameId = game.id {
                                        HStack {
                                            Button(action: {
                                                viewModel.toggleGameSelection(gameId)
                                            }) {
                                                Image(systemName: viewModel.selectedGamesToRecover.contains(gameId) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("ID: \(gameId)")
                                                    .font(.caption)
                                                Text("Licence: \(game.licence_name ?? "N/A")")
                                                    .font(.body)
                                                Text("Prix: \(String(format: "%.2f", game.prix)) €")
                                                    .font(.caption)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                viewModel.toggleGameSelection(gameId)
                                                viewModel.recoverSelectedGames()
                                            }) {
                                                Text("Récupérer")
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.green)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // Bouton pour récupérer tous les jeux sélectionnés
                                if !viewModel.selectedGamesToRecover.isEmpty {
                                    Button(action: {
                                        viewModel.recoverSelectedGames()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.doc.fill")
                                            Text("Récupérer \(viewModel.selectedGamesToRecover.count) jeu(x) sélectionné(s)")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .padding(.top)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationBarTitle("Statistiques Vendeur", displayMode: .inline)
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
        }
    }
}

struct SellerStatsView_Previews: PreviewProvider {
    static var previews: some View {
        SellerStatsView()
    }
}
