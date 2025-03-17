//
//  APIService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import SwiftUI

/// Represents possible errors that can occur during API operations
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case invalidResponse
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .serverError(let statusCode, let errorMessage):
            return "Erreur serveur (\(statusCode)): \(errorMessage)"
        case .invalidResponse:
            return "Réponse invalide"
        case .unauthorized:
            return "Non autorisé. Veuillez vous connecter."
        }
    }
}

/// Core service responsible for handling all network communication with the backend API
class APIService {
    private let apiBaseURL: String
    private let httpSession: URLSession
    private var securityToken: String?
    
    /// Shared singleton instance for app-wide use
    static let shared = APIService()
    
    /// Initialize the API service
    /// - Parameters:
    ///   - apiBaseURL: The base URL for all API requests
    ///   - httpSession: The URL session to use for network requests
    init(apiBaseURL: String = "https://back-projet-web-s7-de95e4be6979.herokuapp.com/api", 
         httpSession: URLSession = .shared) {
        self.apiBaseURL = apiBaseURL
        self.httpSession = httpSession
    }
    
    /// Set the authentication token for secured API endpoints
    /// - Parameter token: The JWT or other authentication token
    func setSecurityToken(_ token: String) {
        self.securityToken = token
    }
    
    /// Makes a network request to the specified endpoint and decodes the response
    /// - Parameters:
    ///   - endpoint: The API endpoint path (will be appended to the base URL)
    ///   - httpMethod: The HTTP method (GET, POST, PUT, DELETE, etc.)
    ///   - requestBody: Optional data to send in the request body
    /// - Returns: The decoded response object of type T
    /// - Throws: APIError if the request fails
    func request<ResponseType: Decodable>(
        _ endpoint: String, 
        httpMethod: String = "GET", 
        requestBody: Data? = nil
    ) async throws -> ResponseType {
        guard let fullRequestURL = URL(string: "\(apiBaseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var httpRequest = URLRequest(url: fullRequestURL)
        httpRequest.httpMethod = httpMethod
        httpRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let securityToken = securityToken {
            httpRequest.addValue("Bearer \(securityToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let requestBody = requestBody {
            httpRequest.httpBody = requestBody
        }
        
        do {
            let (responseData, serverResponse) = try await httpSession.data(for: httpRequest)
            
            #if DEBUG
            let responseText = String(data: responseData, encoding: .utf8) ?? "Invalid data"
            print("API Response for \(endpoint): \(responseText)")
            #endif
            
            guard let httpResponse = serverResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            let responseJsonDecoder = JSONDecoder()
            responseJsonDecoder.dateDecodingStrategy = .iso8601
            
            return try responseJsonDecoder.decode(ResponseType.self, from: responseData)
            
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Empty response type for endpoints that don't return data
    struct EmptyResponse: Decodable {}
}

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
