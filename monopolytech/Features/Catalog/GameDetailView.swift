//
//  GameDetailView.swift
//  monopolytech
//
//  Created by hugo on 18/03/2024.
//

import SwiftUI

/// Vue détaillée d'un jeu du catalogue
struct GameDetailView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec titre et prix
                    VStack(spacing: 16) {
                        Text(game.licence_name ?? "Jeu inconnu")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Prix mis en évidence
                        Text("\(formatPrice(game.prix)) €")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                    
                    // Carte d'informations principales
                    VStack(spacing: 16) {
                        // Prix min et max
                        HStack(spacing: 20) {
                            VStack(alignment: .center) {
                                Text("Prix min")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(formatPrice(game.prix)) €")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(alignment: .center) {
                                Text("Prix max")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(formatPrice(game.prix_max)) €")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Quantité
                        VStack(alignment: .center, spacing: 4) {
                            Text("Quantité disponible")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(game.quantite)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Informations détaillées                        
                        InfoRow(title: "Éditeur", value: game.editeur_nom, icon: "building.fill")
                        
                        if let depotId = game.depot_id {
                            InfoRow(title: "Dépôt", value: "\(depotId)", icon: "archivebox.fill")
                        }
                        
                        // Statut
                        if let status = game.statut {
                            StatusView(status: status)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    /// Formate un prix pour l'affichage
    /// - Parameter price: Le prix à formater
    /// - Returns: Le prix formaté en tant que chaîne de caractères
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
    
    /// Formate une date pour l'affichage
    /// - Parameter date: La date à formater
    /// - Returns: La date formatée en tant que chaîne de caractères
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - Vues de support
/// Vue affichant le statut d'un jeu
struct StatusView: View {
    let status: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(status == "available" ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(status == "available" ? "Disponible" : "Non disponible")
                .font(.headline)
                .foregroundColor(status == "available" ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(status == "available" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

