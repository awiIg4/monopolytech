//
//  GestionService.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation

/// Service pour les fonctionnalités de gestion globale
class GestionService {
    static let shared = GestionService()
    
    private let apiService = APIService.shared
    private let endpoint = "gestion"
    
    private init() {}
    
    /// Récupère le bilan financier de la session courante
    /// - Returns: Le bilan financier
    /// - Throws: APIError si la requête échoue
    func getBilanCurrentSession() async throws -> BilanModel {
        do {
            print("📊 Récupération du bilan de la session courante...")
            
            let (bilanData, statusCode) = try await apiService.request(
                "\(endpoint)/bilan",
                returnRawResponse: true
            )
            
            // Debug de la réponse brute
            let responseString = String(data: bilanData, encoding: .utf8) ?? "Données illisibles"
            print("📊 BILAN RESPONSE [Code: \(statusCode)]:\n\(responseString)")
            
            // Décodage de la réponse
            return try JSONDecoder().decode(BilanModel.self, from: bilanData)
        } catch {
            print("❌ ERREUR lors de la récupération du bilan: \(error)")
            throw error
        }
    }
}
