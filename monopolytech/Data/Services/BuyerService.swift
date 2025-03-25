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
        // Encoder l'email pour l'URL
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
        
        do {
            // Récupérer les données brutes
            let (data, statusCode) = try await apiService.request(
                "\(endpoint)/\(encodedEmail)",
                httpMethod: "GET",
                returnRawResponse: true
            )
            
            // Vérifier que le statut est OK
            guard (200...299).contains(statusCode) else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(statusCode, errorMessage)
                } else {
                    throw APIError.serverError(statusCode, "Erreur lors de la récupération de l'acheteur")
                }
            }
            
            // Décoder la réponse directement vers le modèle Buyer
            let decoder = JSONDecoder()
            let buyer = try decoder.decode(Buyer.self, from: data)
            return buyer
        } catch {
            throw error
        }
    }
    
    /// Enregistre un nouvel acheteur
    /// - Parameters:
    ///   - nom: Nom de l'acheteur
    ///   - email: Email de l'acheteur
    ///   - telephone: Numéro de téléphone de l'acheteur
    ///   - adresse: Adresse de l'acheteur
    /// - Returns: Message de confirmation
    /// - Throws: APIError si la requête échoue
    func registerBuyer(nom: String, email: String, telephone: String, adresse: String) async throws -> String {
        // Préparation des données pour l'API
        let buyerRequest: [String: Any] = [
            "nom": nom,
            "email": email,
            "telephone": telephone,
            "adresse": adresse
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: buyerRequest)
        
        do {
            // Effectuer la requête
            let (data, statusCode) = try await apiService.request(
                "\(endpoint)/register",
                httpMethod: "POST",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Vérifier que le statut est OK
            guard (200...299).contains(statusCode) else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(statusCode, errorMessage)
                } else {
                    throw APIError.serverError(statusCode, "Erreur lors de l'enregistrement de l'acheteur")
                }
            }
            
            // Retourner le message de succès
            return String(data: data, encoding: .utf8) ?? "Compte acheteur créé avec succès."
        } catch {
            throw error
        }
    }
}

