//
//  GameService.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation

/// Service responsible for game-related API operations
class GameService {
    /// Specific endpoint for game-related API
    let gameEndpoint = "jeux/"
    
    /// The underlying API service used for network requests
    private let apiService: APIService
    
    /// Shared singleton instance for app-wide use
    static let shared = GameService()
    
    /// Initialize the Game service
    /// - Parameter apiService: The API service to use for requests
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    /// Fetch all games with optional search parameters
    /// - Parameter query: Optional search query to filter games
    /// - Returns: Array of Game objects
    /// - Throws: APIError if the request fails
    func fetchGames(query: String? = nil) async throws -> [Game] {
        let endpoint = query != nil ? gameEndpoint + "rechercher?q=\(query!)" : gameEndpoint + "rechercher"
        
        do {
            // Define a DTO that matches the API response structure
            struct GameDTO: Decodable {
                let quantite: Int
                let prix_min: Double
                let prix_max: Double
                let licence_nom: String
                let editeur_nom: String
                
                // Convert response to our Game model
                func toGame() -> Game {
                    return Game(
                        id: UUID().uuidString,
                        licence_id: UUID().uuidString,
                        licence_name: licence_nom,
                        prix: prix_min,
                        prix_max: prix_max,
                        quantite: quantite,
                        editeur_nom: editeur_nom,
                        statut: "available",
                        depot_id: nil,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
            }
            
            // Make the request and convert response
            let gamesDTO: [GameDTO] = try await apiService.request(endpoint)
            return gamesDTO.map { $0.toGame() }
        } catch {
            throw error
        }
    }
    
    /// Fetch a specific game by ID
    /// - Parameter id: The ID of the game to fetch
    /// - Returns: A single Game object
    /// - Throws: APIError if the request fails
    func fetchGame(id: String) async throws -> Game {
        return try await apiService.request("\(gameEndpoint)\(id)")
    }
    
    /// Deposit one or more games for sale
    /// - Parameter request: Structured request containing game details
    /// - Returns: Array of deposited games
    /// - Throws: APIError if the request fails
    func depositGames(request: GameDepositRequest) async throws -> [Game] {
        do {
            let requestData = try JSONEncoder().encode(request)
            
            // Make the request
            let (responseData, statusCode) = try await apiService.request(
                "jeux/deposer",
                httpMethod: "POST",
                requestBody: requestData,
                returnRawResponse: true
            )
            
            // Success handling
            if (200...299).contains(statusCode) {
                do {
                    let games = try JSONDecoder().decode([Game].self, from: responseData)
                    return games
                } catch {
                    do {
                        let game = try JSONDecoder().decode(Game.self, from: responseData)
                        return [game]
                    } catch {
                        // Even if we can't decode the response, return an empty array for success status
                        return []
                    }
                }
            } else {
                throw APIError.serverError(statusCode, "Game deposit failed with status \(statusCode)")
            }
        } catch {
            throw error
        }
    }

    /// Convenience method to deposit a single game
    /// - Parameters:
    ///   - licenseId: ID of the game license
    ///   - price: Price of the game
    ///   - quantity: Number of copies to deposit
    ///   - sellerId: ID of the seller
    ///   - promoCode: Optional promotional code
    /// - Returns: Array of deposited games
    /// - Throws: APIError if the request fails
    func depositGame(licenseId: String, price: Double, quantity: Int, sellerId: String, promoCode: String? = nil) async throws -> [Game] {
        let request = GameDepositRequest(
            licence: [Int(licenseId)!],  // Convertir en Int
            prix: [price],
            quantite: [quantity],
            code_promo: promoCode,
            id_vendeur: sellerId
        )
        
        return try await depositGames(request: request)
    }

    /// Récupère les jeux qui ne sont pas encore en rayon
    /// - Returns: Liste des jeux non mis en rayon
    /// - Throws: APIError si la requête échoue
    func fetchGamesNotInSale() async throws -> [Game] {
        do {
            // Utiliser returnRawResponse pour accéder aux données brutes
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)pas_en_rayon",
                returnRawResponse: true
            )
            
            // Déboguer la réponse brute
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            print("📄 GAMES NOT IN SALE RESPONSE [Status: \(statusCode)]:\n\(responseString)")
            
            // Vérifier le code de statut
            if (200...299).contains(statusCode) {
                // Structure DTO adaptée au format de réponse réel
                struct GameDTO: Decodable {
                    let id: Int
                    let licence_id: Int
                    let prix: String // <- Modifié: prix en String au lieu de Double
                    let statut: String?
                    let depot_id: Int?
                    let depot: DepotDTO?
                    
                    struct DepotDTO: Decodable {
                        let id: Int
                        let vendeur_id: Int?
                        let session_id: Int?
                    }
                    
                    func toGame() -> Game {
                        // Convertir le prix String en Double
                        let priceDouble = Double(prix.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        
                        return Game(
                            id: String(id),
                            licence_id: String(licence_id),
                            licence_name: nil, // À récupérer séparément via LicenseService
                            prix: priceDouble,
                            prix_max: priceDouble,
                            quantite: 1,
                            editeur_nom: "",
                            statut: statut,
                            depot_id: depot_id != nil ? depot_id! : 0,
                            createdAt: nil,
                            updatedAt: nil
                        )
                    }
                }
                
                // Décodage direct en tableau
                do {
                    let decoder = JSONDecoder()
                    let gamesDTO = try decoder.decode([GameDTO].self, from: responseData)
                    return gamesDTO.map { $0.toGame() }
                } catch {
                    print("❌ Erreur de décodage: \(error)")
                    return []
                }
            } else {
                throw APIError.serverError(statusCode, "Récupération des jeux échouée")
            }
        } catch {
            print("❌ Erreur lors de la récupération des jeux non mis en rayon: \(error)")
            throw error
        }
    }

    /// Met des jeux en rayon (change leur statut en "en vente")
    /// - Parameter gameIds: Liste des identifiants des jeux à mettre en rayon
    /// - Returns: Liste des jeux mis à jour
    /// - Throws: APIError si la requête échoue
    func putGamesForSale(gameIds: [String]) async throws -> [Game] {
        // Convertir les IDs de String à Int
        let intIds = gameIds.compactMap { Int($0) }
        
        // Préparer la requête
        let payload: [String: Any] = [
            "jeux_ids": intIds,
            "nouveau_statut": "en vente"
        ]
        
        do {
            // Encoder le payload
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            // Effectuer la requête avec le status code pour debug
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)updateStatus",
                httpMethod: "PUT",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Debug - afficher la réponse brute
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            print("📄 PUT GAMES FOR SALE RESPONSE [Status: \(statusCode)]:\n\(responseString)")
            
            // Vérifier le code de statut
            if (200...299).contains(statusCode) {
                // La réponse est un succès, mais pas forcément au format attendu
                // Créer un jeu factice basé sur les IDs envoyés pour indiquer le succès
                return gameIds.map { id in
                    Game(
                        id: id,
                        licence_id: "",
                        licence_name: "Mis en rayon avec succès",
                        prix: 0,
                        prix_max: 0,
                        quantite: 1,
                        editeur_nom: "",
                        statut: "en vente",
                        depot_id: nil,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
            } else {
                // Si la requête a échoué, lancer une erreur
                throw APIError.serverError(statusCode, responseString)
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Erreur lors de la mise en rayon: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}
