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
}
