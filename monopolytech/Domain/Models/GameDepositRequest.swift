//
//  GameDepositRequest.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Modèle représentant une requête de dépôt de jeu, correspondant à l'API
struct GameDepositRequest: Codable {
    let licence: [Int]
    let prix: [Double]
    let quantite: [Int]
    let code_promo: String?
    let id_vendeur: String
    
    /// Clés pour assurer la correspondance avec l'API
    enum CodingKeys: String, CodingKey {
        case licence
        case prix
        case quantite
        case code_promo
        case id_vendeur
    }
}
