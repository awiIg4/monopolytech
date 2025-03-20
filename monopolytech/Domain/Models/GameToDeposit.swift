//
//  GameToDeposit.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Modèle représentant un jeu à déposer, utilisé dans la vue
struct GameToDeposit: Identifiable {
    let id = UUID()
    let licenseId: String
    let licenseName: String
    let price: Double
    let quantity: Int
}
