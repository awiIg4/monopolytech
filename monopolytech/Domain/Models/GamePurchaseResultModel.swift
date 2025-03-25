//
//  GamePurchaseResult.swift
//  monopolytech
//
//  Created by eugenio on 29/03/2025.
//

import Foundation

/// Résultat d'un achat de jeux
struct GamePurchaseResult: Codable {
    let totalAmount: Double
    let discount: Double
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
    
    var total: Double {
        return price + commission
    }
}
