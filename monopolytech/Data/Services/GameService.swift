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
        } catch let error as APIError {
            #if DEBUG
            print("Error fetching games: \(error.localizedDescription)")
            #endif
            throw error
        } catch {
            let wrappedError = APIError.networkError(error)
            #if DEBUG
            print("Unexpected error fetching games: \(wrappedError.localizedDescription)")
            #endif
            throw wrappedError
        }
    }
    
    /// Fetch a specific game by ID
    /// - Parameter id: The ID of the game to fetch
    /// - Returns: A single Game object
    /// - Throws: APIError if the request fails
    func fetchGame(id: String) async throws -> Game {
        do {
            return try await apiService.request("\(gameEndpoint)\(id)")
        } catch {
            throw APIError.networkError(error)
        }
    }
}
