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
    func setSecurityToken(_ token: String?) {
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
    
    /// TODO: Ensure usage or remove
    /// Empty response type for endpoints that don't return data
    struct EmptyResponse: Decodable {
    }
}
