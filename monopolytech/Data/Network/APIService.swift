//
//  APIService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import SwiftUI

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

// Core API service that handles network communication
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
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
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
            
            // Debug the response in development
            #if DEBUG
            let jsonString = String(data: data, encoding: .utf8) ?? "Invalid data"
            print("API Response for \(endpoint): \(jsonString)")
            #endif
            
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
    
    // Helper struct for empty responses
    struct EmptyResponse: Decodable {}
}
