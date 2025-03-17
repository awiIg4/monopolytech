//
//  APIService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation

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
        case .serverError(let code, let message):
            return "Erreur serveur (\(code)): \(message)"
        case .invalidResponse:
            return "Réponse invalide"
        case .unauthorized:
            return "Non autorisé. Veuillez vous connecter."
        }
    }
}

class APIService {
    // URL de base de l'API
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    
    static let shared = APIService()
    
    init(baseURL: String = "https://back-projet-web-s7-de95e4be6979.herokuapp.com/api", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - Generic Request Methods
    
    private func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Game Endpoints
    
    func fetchGames() async throws -> [Game] {
        do {
            let url = URL(string: "\(baseURL)/jeux/rechercher")!
            let (data, _) = try await session.data(for: URLRequest(url: url))
            
            // Debug the response
            let jsonString = String(data: data, encoding: .utf8) ?? "Invalid data"
            print("API Response: \(jsonString)")
            
            // Define a DTO that matches exactly what the API returns
            struct GameDTO: Decodable {
                let quantite: Int
                let prix_min: Double
                let prix_max: Double
                let licence_nom: String
                let editeur_nom: String
                
                // Convert to your app's Game model
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
            
            // Decode the array directly
            let gamesDTO = try JSONDecoder().decode([GameDTO].self, from: data)
            
            // Convert to your app's Game model
            return gamesDTO.map { $0.toGame() }
        } catch {
            print("Debug error: \(error)")
            throw error
        }
    }
    
    func fetchGame(id: String) async throws -> Game {
        return try await request("games/\(id)")
    }
    
    func createGame(_ game: Game) async throws -> Game {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(game)
        
        return try await request("games", method: "POST", body: data)
    }
    
    func updateGame(_ game: Game) async throws -> Game {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(game)
        
        return try await request("games/\(game.id)", method: "PUT", body: data)
    }
    
    func deleteGame(id: String) async throws {
        _ = try await request("games/\(id)", method: "DELETE") as EmptyResponse
    }
    
    // MARK: - Category Endpoints
    
    func fetchCategories() async throws -> [Category] {
        return try await request("categories")
    }
    
    // MARK: - Helper Types
    
    private struct EmptyResponse: Decodable {}
}
