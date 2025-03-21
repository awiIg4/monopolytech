//
//  GameStockToSaleView.swift
//  monopolytech
//
//  Created by eugenio on 28/03/2025.
//

import SwiftUI

struct GameStockToSaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GameStockToSaleViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Titre
                    Text("Mettre des jeux en rayon")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    if viewModel.isLoading {
                        ProgressView("Chargement des jeux...")
                            .padding()
                    } else if viewModel.games.isEmpty {
                        VStack {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("Aucun jeu en attente")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                    } else {
                        // Liste des jeux
                        VStack(spacing: 16) {
                            ForEach(viewModel.games, id: \.id) { game in
                                GameRow(
                                    game: game,
                                    licenseName: viewModel.getLicenseName(for: game),
                                    onPutForSale: {
                                        viewModel.putGameForSale(game)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Mettre en rayon", displayMode: .inline)
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

// Composant pour afficher une ligne de jeu
struct GameRow: View {
    let game: Game
    let licenseName: String
    let onPutForSale: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // ID et licence
                    HStack {
                        Text("#\(game.id ?? "")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(game.statut ?? "N/A")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Nom de la licence
                    Text(licenseName)
                        .font(.headline)
                    
                    // Prix
                    Text("\(String(format: "%.2f", game.prix)) €")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Bouton pour mettre en rayon
                Button(action: onPutForSale) {
                    Text("Mettre en rayon")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct GameStockToSaleView_Previews: PreviewProvider {
    static var previews: some View {
        GameStockToSaleView()
    }
}