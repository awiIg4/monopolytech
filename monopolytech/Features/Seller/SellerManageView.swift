//
//  SellerManageView.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import SwiftUI

struct SellerManageView: View {
    @StateObject private var viewModel = SellerManageViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Gérer les Vendeurs")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                // Formulaire de recherche
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Rechercher par email", text: $viewModel.searchEmail)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                        
                        if !viewModel.searchEmail.isEmpty {
                            Button(action: {
                                viewModel.clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Button(action: {
                        Task {
                            await viewModel.searchSeller()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Image(systemName: "person.fill.questionmark")
                            Text("Rechercher le vendeur")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading || viewModel.searchEmail.isEmpty)
                    .opacity(viewModel.searchEmail.isEmpty ? 0.6 : 1)
                }
                .padding()
                
                // Affichage des résultats
                if let seller = viewModel.currentSeller {
                    SellerDetailCard(seller: seller, stats: viewModel.sellerStats)
                        .padding(.horizontal)
                } else if viewModel.isLoading {
                    ProgressView("Recherche en cours...")
                        .padding()
                }
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Erreur"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationBarTitle("Gérer les vendeurs", displayMode: .inline)
    }
}

/// Vue de détail d'un vendeur
struct SellerDetailCard: View {
    let seller: User  // Utilise User au lieu de Seller
    let stats: SellerStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Informations du vendeur")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Nom", value: seller.nom, icon: "person.fill")
                    InfoRow(title: "Email", value: seller.email, icon: "envelope.fill")
                    InfoRow(title: "Téléphone", value: seller.telephone, icon: "phone.fill")
                    if let adresse = seller.adresse {
                        InfoRow(title: "Adresse", value: adresse, icon: "location.fill")
                    }
                    if let id = seller.id {
                        InfoRow(title: "ID", value: id, icon: "person.badge.key.fill")
                    } else {
                        InfoRow(title: "ID", value: "N/A", icon: "person.badge.key.fill")
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Statistiques
            if let stats = stats {
                Text("Statistiques")
                    .font(.headline)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        StatRow(title: "Jeux déposés", value: "\(stats.totalDepositedGames)", icon: "shippingbox.fill")
                        StatRow(title: "Jeux vendus", value: "\(stats.totalSoldGames)", icon: "cart.fill")
                        StatRow(title: "Gains totaux", value: "\(stats.totalEarned) €", icon: "creditcard.fill")
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct SellerManageView_Previews: PreviewProvider {
    static var previews: some View {
        SellerManageView()
    }
}
