//
//  SellerService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Service pour gérer les vendeurs
class SellerService {
    static let shared = SellerService()
    
    private let apiService = APIService.shared
    private let endpoint = "vendeurs"
    
    private init() {}
    
    /// Récupère un vendeur par son email
    func getSellerByEmail(email: String) async throws -> User {
        // Définir un DTO pour correspondre à la structure exacte de l'API
        struct SellerDTO: Decodable {
            let id: Int
            let nom: String
            let email: String
            let telephone: String?
            let adresse: String?
            
            // Convertir en modèle de domaine
            func toModel() -> User {
                return User(
                    id: String(id),  // Conversion explicite de Int vers String
                    nom: nom,
                    email: email,
                    telephone: telephone ?? "",
                    adresse: adresse,
                    type_utilisateur: "vendeur"  // Type d'utilisateur fixe pour un vendeur
                )
            }
        }
        
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        
        do {
            // Utiliser le DTO pour le décodage
            let sellerDTO: SellerDTO = try await apiService.request("\(endpoint)/\(encodedEmail)")
            return sellerDTO.toModel()
        } catch {
            print("❌ Seller fetch error: \(error)")
            throw error
        }
    }
}
