//
//  GestionService.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation

/// Service pour les fonctionnalités de gestion globale
class GestionService {
    /// Instance partagée pour l'accès au service
    static let shared = GestionService()
    
    private let apiService = APIService.shared
    private let endpoint = "gestion"
    
    private init() {}
    
    /// Récupère le bilan financier de la session courante
    /// - Returns: Le bilan financier contenant les informations de la session
    /// - Throws: APIError si la requête échoue
    func getBilanCurrentSession() async throws -> BilanModel {
        do {
            let (bilanData, statusCode) = try await apiService.request(
                "\(endpoint)/bilan",
                returnRawResponse: true
            )
            
            // Vérification du statut de la réponse
            guard (200...299).contains(statusCode) else {
                throw APIError.serverError(statusCode, "Échec de récupération du bilan")
            }
            
            // Décodage de la réponse vers le modèle BilanModel
            return try JSONDecoder().decode(BilanModel.self, from: bilanData)
        } catch {
            throw error
        }
    }
}
