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
    /// - Returns: La réponse du serveur sous forme de chaîne de texte
    /// - Throws: APIError si la requête échoue
    func createManager(_ manager: CreateManagerRequest) async throws -> String {
        do {
            let jsonData = try manager.toJSONData()

            // Utiliser requestWithHeaders pour obtenir les données brutes
            let (data, statusCode, _) = try await apiService.requestWithHeaders(
                endpoint,
                httpMethod: "POST",
                requestBody: jsonData
            )
            
            // Gérer les erreurs potentielles
            if !(200...299).contains(statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(statusCode, errorMessage)
            }
            
            // Convertir les données en chaîne de texte
            if let responseString = String(data: data, encoding: .utf8) {
                // Assurons-nous que la réponse contient "succès" si elle est vide ou peu claire
                if responseString.isEmpty || !responseString.contains("succès") {
                    return "Compte gestionnaire créé avec succès."
                }
                
                return responseString
            } else {
                return "Compte gestionnaire créé avec succès."
            }
        } catch {
            throw error
        }
    }
}

