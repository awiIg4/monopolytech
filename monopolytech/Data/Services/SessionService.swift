//
//  SessionService.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation

/// Service responsable des opérations API liées aux sessions
class SessionService {
    /// Point de terminaison spécifique pour l'API des sessions
    private let endpoint = "sessions"
    
    /// Service API sous-jacent utilisé pour les requêtes réseau
    private let apiService = APIService.shared
    
    /// Instance singleton partagée pour une utilisation dans toute l'application
    static let shared = SessionService()
    
    private init() {}
    
    /// Modèle pour une session
    struct Session: Codable, Identifiable {
        let id: Int
        let date_debut: String
        let date_fin: String
        let valeur_commission: Int
        let commission_en_pourcentage: Bool
        let valeur_frais_depot: Int
        let frais_depot_en_pourcentage: Bool
        let createdAt: String?
        let updatedAt: String?
    }
    
    /// Requête pour créer ou mettre à jour une session
    struct SessionRequest: Encodable {
        let date_debut: String
        let date_fin: String
        let valeur_commission: Int
        let commission_en_pourcentage: Bool
        let valeur_frais_depot: Int
        let frais_depot_en_pourcentage: Bool
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Créer une nouvelle session
    /// - Parameter session: Les données de la session à créer
    /// - Returns: La session créée
    /// - Throws: APIError si la requête échoue
    func createSession(_ session: SessionRequest) async throws -> Session {
        do {
            let jsonData = try session.toJSONData()
            
            return try await apiService.request(
                endpoint,
                httpMethod: "POST",
                requestBody: jsonData
            )
        } catch {
            print("❌ Erreur lors de la création de la session: \(error)")
            throw error
        }
    }
    
    /// Récupérer toutes les sessions
    /// - Returns: Liste des sessions
    /// - Throws: APIError si la requête échoue
    func getAllSessions() async throws -> [Session] {
        do {
            return try await apiService.request(endpoint)
        } catch {
            print("❌ Erreur lors de la récupération des sessions: \(error)")
            throw error
        }
    }
    
    /// Récupérer la session courante
    /// - Returns: La session courante ou nil si aucune n'est active
    /// - Throws: APIError si la requête échoue
    func getCurrentSession() async throws -> Session? {
        do {
            return try await apiService.request("\(endpoint)/current")
        } catch let error as APIError {
            if case .serverError(404, _) = error {
                return nil
            }
            print("❌ Erreur lors de la récupération de la session courante: \(error)")
            throw error
        } catch {
            print("❌ Erreur lors de la récupération de la session courante: \(error)")
            throw error
        }
    }
    
    /// Récupérer une session par son ID
    /// - Parameter id: ID de la session
    /// - Returns: La session correspondante
    /// - Throws: APIError si la requête échoue
    func getSession(id: Int) async throws -> Session {
        do {
            return try await apiService.request("\(endpoint)/\(id)")
        } catch {
            print("❌ Erreur lors de la récupération de la session \(id): \(error)")
            throw error
        }
    }
    
    /// Mettre à jour une session existante
    /// - Parameters:
    ///   - id: ID de la session à mettre à jour
    ///   - session: Nouvelles données de la session
    /// - Returns: La session mise à jour
    /// - Throws: APIError si la requête échoue
    func updateSession(id: Int, session: SessionRequest) async throws -> Session {
        do {
            let jsonData = try session.toJSONData()
            
            return try await apiService.request(
                "\(endpoint)/\(id)",
                httpMethod: "PUT",
                requestBody: jsonData
            )
        } catch {
            print("❌ Erreur lors de la mise à jour de la session \(id): \(error)")
            throw error
        }
    }
    
    /// Supprimer une session
    /// - Parameter id: ID de la session à supprimer
    /// - Returns: Message de confirmation
    /// - Throws: APIError si la requête échoue
    func deleteSession(id: Int) async throws -> String {
        do {
            let (data, statusCode) = try await apiService.request(
                "\(endpoint)/\(id)",
                httpMethod: "DELETE",
                returnRawResponse: true
            )
            
            if !(200...299).contains(statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(statusCode, errorMessage)
            }
            
            return String(data: data, encoding: .utf8) ?? "Session supprimée avec succès."
        } catch {
            print("❌ Erreur lors de la suppression de la session \(id): \(error)")
            throw error
        }
    }
    
    /// Formatte une date pour l'API
    /// - Parameter date: Date à formater
    /// - Returns: Chaîne de caractères au format ISO8601
    func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

