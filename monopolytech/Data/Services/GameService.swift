//
//  GameService.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation
import SwiftUI

class GameService {
    private let apiService = APIService.shared
    static let shared = GameService()
    
    // Fetch all games with search parameters
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
                
                // Map to our domain model
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
            
            // Make the request and convert
            let gamesDTO: [GameDTO] = try await apiService.request(endpoint)
            return gamesDTO.map { $0.toGame() }
        } catch {
            // Log the error and re-throw
            print("Error fetching games: \(error)")
            throw error
        }
    }
    
    // Fetch a specific game by ID
    func fetchGame(id: String) async throws -> Game {
        return try await apiService.request("jeux/\(id)")
    }
    
    // Create a new game
    func createGame(_ game: Game) async throws -> Game {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(game)
        
        return try await apiService.request("jeux", method: "POST", body: data)
    }
    
    // Update an existing game
    func updateGame(_ game: Game) async throws -> Game {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(game)
        
        return try await apiService.request("jeux/\(game.id)", method: "PUT", body: data)
    }
    
    // Delete a game
    func deleteGame(id: String) async throws {
        _ = try await apiService.request("jeux/\(id)", method: "DELETE") as APIService.EmptyResponse
    }
}
