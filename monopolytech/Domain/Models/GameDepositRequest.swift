//
//  GameDepositRequest.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

// TODO: create and move to new DTO group
/// Modèle représentant une requête de dépôt de jeu, correspondant à l'API
struct GameDepositRequest: Codable {
    /// Tableau des identifiants de licences (doit être des entiers pour l'API)
    let licence: [Int]
    /// Tableau des prix pour chaque jeu
    let prix: [Double]
    /// Tableau des quantités pour chaque jeu
    let quantite: [Int]
    /// Code promo optionnel
    let code_promo: String?
    /// ID du vendeur
    let id_vendeur: String
    
    // Ensure these keys match API expectations
    enum CodingKeys: String, CodingKey {
        case licence
        case prix
        case quantite
        case code_promo
        case id_vendeur
    }
}
