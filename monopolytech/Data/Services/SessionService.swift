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
            throw error
        } catch {
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

extension Session {
    /// Convertit un modèle Session en SessionService.Session (pour les API)
    func toServiceModel() -> SessionService.Session {
        return SessionService.Session(
            id: id ?? 0,
            date_debut: date_debut,
            date_fin: date_fin,
            valeur_commission: Int(valeur_commission),  // Conversion de Double à Int
            commission_en_pourcentage: commission_en_pourcentage,
            valeur_frais_depot: Int(valeur_frais_depot),  // Conversion de Double à Int
            frais_depot_en_pourcentage: frais_depot_en_pourcentage,
            createdAt: nil,  // Utiliser nil si pas disponible
            updatedAt: nil   // Utiliser nil si pas disponible
        )
    }
}

extension SessionService.Session {
    /// Convertit un SessionService.Session en modèle de domaine Session
    func toDomainModel() -> Session {
        return Session(
            id: id,
            date_debut: date_debut,
            date_fin: date_fin,
            valeur_commission: Double(valeur_commission),  // Conversion de Int à Double
            commission_en_pourcentage: commission_en_pourcentage,
            valeur_frais_depot: Double(valeur_frais_depot),  // Conversion de Int à Double
            frais_depot_en_pourcentage: frais_depot_en_pourcentage
        )
    }
}

extension SessionService {
    /// Récupère toutes les sessions et les convertit en modèles de domaine
    /// - Returns: Liste des sessions au format du domaine
    /// - Throws: APIError si la requête échoue
    func getAllSessionsAsDomainModels() async throws -> [monopolytech.Session] {
        let apiSessions = try await getAllSessions()
        return apiSessions.map { $0.toDomainModel() }
    }
}

