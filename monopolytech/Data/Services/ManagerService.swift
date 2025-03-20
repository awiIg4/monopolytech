//
//  ManagerService.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation

/// Service responsable des opérations API liées aux gestionnaires
class ManagerService {
    /// Point de terminaison spécifique pour l'API des gestionnaires
    private let endpoint = "gestionnaires/register"
    
    /// Service API sous-jacent utilisé pour les requêtes réseau
    private let apiService = APIService.shared
    
    /// Instance singleton partagée pour une utilisation dans toute l'application
    static let shared = ManagerService()
    
    private init() {}
    
    /// Structure pour la création d'un gestionnaire
    struct CreateManagerRequest: Encodable {
        let nom: String
        let email: String
        let telephone: String
        let adresse: String
        let motdepasse: String
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Créer un nouveau gestionnaire
    /// - Parameter manager: Les données du gestionnaire à créer
    /// - Returns: Void - ne retourne rien
    /// - Throws: APIError si la requête échoue
    func createManager(_ manager: CreateManagerRequest) async throws {
        do {
            let jsonData = try manager.toJSONData()

            let _: String = try await apiService.request(endpoint,
                                                         httpMethod: "POST",
                                                         requestBody: jsonData)
            
            print("Gestionnaire créé avec succès")
        } catch {
            print("❌ Erreur de création: \(error)")
            throw error
        }
    }
}

