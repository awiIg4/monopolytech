//
//  BuyerService.swift
//  monopolytech
//
//  Created by eugenio on 29/03/2025.
//

import Foundation

/// Service pour gérer les acheteurs
class BuyerService {
    static let shared = BuyerService()
    
    private let apiService = APIService.shared
    private let endpoint = "acheteurs"
    
    private init() {}
    
    /// Récupère un acheteur par son email
    /// - Parameter email: Email de l'acheteur à rechercher
    /// - Returns: L'acheteur trouvé
    /// - Throws: APIError si la requête échoue
    func getBuyerByEmail(email: String) async throws -> Buyer {
        struct BuyerDTO: Decodable {
            let id: Int
            let nom: String
            let email: String
            let telephone: String?
            let adresse: String?
            
            func toModel() -> Buyer {
                return Buyer(
                    id: String(id),
                    nom: nom,
                    email: email,
                    telephone: telephone,
                    adresse: adresse
                )
            }
        }
        
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        
        do {
            let buyerDTO: BuyerDTO = try await apiService.request("\(endpoint)/\(encodedEmail)")
            return buyerDTO.toModel()
        } catch {
            throw error
        }
    }
}
