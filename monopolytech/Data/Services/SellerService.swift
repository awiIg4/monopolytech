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
    
    /// Requête pour la création d'un vendeur
    struct CreateSellerRequest: Encodable {
        let nom: String
        let email: String
        let telephone: String
        let adresse: String?
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Créer un nouveau vendeur
    /// - Parameter seller: Les données du vendeur à créer
    /// - Returns: Le vendeur créé
    /// - Throws: APIError si la requête échoue
    func createSeller(_ seller: CreateSellerRequest) async throws -> User {
        struct SellerDTO: Decodable {
            let id: Int
            let nom: String
            let email: String
            let telephone: String
            let adresse: String?
            
            func toModel() -> User {
                return User(
                    id: String(id),
                    nom: nom,
                    email: email,
                    telephone: telephone,
                    adresse: adresse,
                    type_utilisateur: "vendeur"
                )
            }
        }
        
        do {
            let jsonData = try seller.toJSONData()
            let sellerDTO: SellerDTO = try await apiService.request(
                "\(endpoint)/register",
                httpMethod: "POST",
                requestBody: jsonData
            )
            return sellerDTO.toModel()
        } catch {
            throw error
        }
    }
    
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
            throw error
        }
    }
    
    /// Récupère les statistiques d'un vendeur
    /// - Parameter sellerId: Identifiant du vendeur
    /// - Returns: Statistiques du vendeur
    func getSellerStats(sellerId: String) async throws -> SellerStats {
        struct SellerStatsDTO: Decodable {
            let nbJeuxVendus: Int
            let nbJeuxDeposes: Int
            let argentGagne: Double
            
            func toModel() -> SellerStats {
                return SellerStats(
                    totalSoldGames: nbJeuxVendus,
                    totalDepositedGames: nbJeuxDeposes,
                    totalEarned: argentGagne
                )
            }
        }
        
        do {
            let statsDTO: SellerStatsDTO = try await apiService.request("\(endpoint)/stats/\(sellerId)")
            return statsDTO.toModel()
        } catch {
            throw error
        }
    }
}

/// Modèle pour les statistiques d'un vendeur
struct SellerStats {
    let totalSoldGames: Int
    let totalDepositedGames: Int
    let totalEarned: Double
}
