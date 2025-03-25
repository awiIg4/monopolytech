//
//  SellerStats.swift
//  monopolytech
//
//  Created by eugenio on 24/03/2025.
//

import Foundation

/// Modèle représentant les statistiques d'un vendeur
struct SellerStats: Equatable {
    // Statistiques globales (toutes sessions)
    let totalRevenueAllSessions: Double
    let totalAmountDue: Double
    
    // Statistiques pour une session spécifique
    let totalSoldGames: Int
    let totalRevenue: Double
    let amountDue: Double
    let totalEarned: Double
    
    // Jeux associés
    let soldGames: [Game]
    let stockGames: [Game]
    let recuperableGames: [Game]
    
    /// Statistiques exemple pour les prévisualisations et tests
    static let placeholder = SellerStats(
        totalRevenueAllSessions: 500.0,
        totalAmountDue: 250.0,
        totalSoldGames: 5,
        totalRevenue: 300.0,
        amountDue: 150.0,
        totalEarned: 200.0,
        soldGames: [Game.placeholder, Game.placeholder],
        stockGames: [Game.placeholder],
        recuperableGames: [Game.placeholder, Game.placeholder, Game.placeholder]
    )
    
    /// Statistiques vides pour les états d'erreur ou d'initialisation
    static let empty = SellerStats(
        totalRevenueAllSessions: 0.0,
        totalAmountDue: 0.0,
        totalSoldGames: 0,
        totalRevenue: 0.0,
        amountDue: 0.0,
        totalEarned: 0.0,
        soldGames: [],
        stockGames: [],
        recuperableGames: []
    )
}
