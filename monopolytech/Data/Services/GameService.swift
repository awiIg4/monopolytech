//
//  GameService.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation

/// Service responsible for game-related API operations
class GameService {
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
        let endpoint = query != nil ? "jeux/rechercher?q=\(query!)" : "jeux/rechercher"
        
        do {
            // Define a DTO that matches the API response structure
            struct GameDTO: Decodable {
                let quantite: Int
                let prix_min: Double
                let prix_max: Double
                let licence_nom: String
                let editeur_nom: String
                
                /// Convert the DTO to our domain model
                func toGame() -> Game {
                    return Game(
                        id: UUID().uuidString, // Generate a temporary ID
                        title: licence_nom,
                        description: nil,
                        price: prix_min,
                        categoryId: nil,
                        category: nil,
                        imageUrl: nil,
                        sellerId: nil,
                        sellerName: editeur_nom,
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
    
    /// Fetch a specific game by its ID
    /// - Parameter id: The unique identifier of the game
    /// - Returns: A Game object
    /// - Throws: APIError if the request fails
    func fetchGame(id: String) async throws -> Game {
        do {
            return try await apiService.request("jeux/\(id)")
        } catch {
            #if DEBUG
            print("Error fetching game with ID \(id): \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    /// Create a new game
    /// - Parameter game: The game object to create
    /// - Returns: The created game with server-assigned ID
    /// - Throws: APIError if the request fails
    func createGame(_ game: Game) async throws -> Game {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(game)
            
            return try await apiService.request("jeux", httpMethod: "POST", requestBody: data)
        } catch let error as EncodingError {
            let wrappedError = APIError.decodingError(error)
            #if DEBUG
            print("Error encoding game: \(wrappedError.localizedDescription)")
            #endif
            throw wrappedError
        } catch {
            #if DEBUG
            print("Error creating game: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    /// Update an existing game
    /// - Parameter game: The game object with updated values
    /// - Returns: The updated game
    /// - Throws: APIError if the request fails
    func updateGame(_ game: Game) async throws -> Game {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(game)
            
            return try await apiService.request("jeux/\(game.id)", httpMethod: "PUT", requestBody: data)
        } catch let error as EncodingError {
            let wrappedError = APIError.decodingError(error)
            #if DEBUG
            print("Error encoding game: \(wrappedError.localizedDescription)")
            #endif
            throw wrappedError
        } catch {
            #if DEBUG
            print("Error updating game: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    /// Delete a game by its ID
    /// - Parameter id: The unique identifier of the game to delete
    /// - Throws: APIError if the request fails
    func deleteGame(id: String) async throws {
        do {
            _ = try await apiService.request("jeux/\(id)", httpMethod: "DELETE") as APIService.EmptyResponse
        } catch {
            #if DEBUG
            print("Error deleting game with ID \(id): \(error.localizedDescription)")
            #endif
            throw error
        }
    }
}
