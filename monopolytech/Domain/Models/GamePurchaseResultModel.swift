//
//  GamePurchaseResult.swift
//  monopolytech
//
//  Created by eugenio on 29/03/2025.
//

import Foundation

/// Résultat d'un achat de jeux
struct GamePurchaseResult: Codable {
    /// Montant total de l'achat
    let totalAmount: Double
    
    /// Montant de la réduction appliquée
    let discount: Double
    
    /// Liste des jeux achetés
    let purchasedGames: [PurchasedGame]
    
    /// Montant final après réduction
    var finalAmount: Double {
        return totalAmount - discount
    }
}

/// Représente un jeu acheté avec ses détails
struct PurchasedGame: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let commission: Double
    let vendorName: String?
    let editorName: String?
    
    /// Prix total incluant la commission
    var total: Double {
        return price + commission
    }
}
