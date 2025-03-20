//
//  GameDepositRequest.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Model representing a game deposit request to the API
struct GameDepositRequest: Codable {
    let licence: [String]
    let prix: [Double]
    let quantite: [Int]
    let code_promo: String?
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
