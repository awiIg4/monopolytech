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
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Makes a network request to the specified endpoint and decodes the response
    /// - Parameters:
    ///   - endpoint: The API endpoint path (will be appended to the base URL)
    ///   - httpMethod: The HTTP method (GET, POST, PUT, DELETE, etc.)
    ///   - requestBody: Optional data to send in the request body
    ///   - returnRawResponse: If true, returns raw data and status code instead of decoded data
    /// - Returns: The decoded response object of type T or raw data with status code
    /// - Throws: APIError if the request fails
    func request<T: Decodable>(
        _ endpoint: String,
        httpMethod: String = "GET",
        requestBody: Data? = nil,
        returnRawResponse: Bool = false
    ) async throws -> T {
        let request = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        do {
            let (data, response) = try await httpSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            // For raw response requests, return the data and status code
            if returnRawResponse, T.self == (Data, Int).self {
                return (data, httpResponse.statusCode) as! T
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            // Decode the response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Overload for returning raw response data and status code
    func request(_ endpoint: String, httpMethod: String = "GET", requestBody: Data? = nil, returnRawResponse: Bool = true) async throws -> (Data, Int) {
        let request = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        let (data, response) = try await httpSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return (data, httpResponse.statusCode)
    }
    
    /// Request that returns raw data, status code, and response headers
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - httpMethod: HTTP method (default: "GET")
    ///   - requestBody: Optional request body data
    /// - Returns: Tuple containing data, status code, and response headers
    /// - Throws: APIError if the request fails
    func requestWithHeaders(_ endpoint: String, 
                           httpMethod: String = "GET", 
                           requestBody: Data? = nil) async throws -> (Data, Int, [AnyHashable: Any]) {
        let request = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        do {
            let (data, response) = try await httpSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            return (data, httpResponse.statusCode, httpResponse.allHeaderFields)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Create a URL request for the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint path (will be appended to the base URL)
    ///   - httpMethod: The HTTP method (GET, POST, PUT, DELETE, etc.)
    ///   - requestBody: Optional data to send in the request body
    /// - Returns: The URL request
    private func createURLRequest(for endpoint: String, httpMethod: String, requestBody: Data? = nil) -> URLRequest {
        guard let fullRequestURL = URL(string: "\(apiBaseURL)/\(endpoint)") else {
            fatalError("Invalid URL: \(apiBaseURL)/\(endpoint)")
        }
        
        var httpRequest = URLRequest(url: fullRequestURL)
        httpRequest.httpMethod = httpMethod
        httpRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let securityToken = securityToken, !securityToken.isEmpty {
            httpRequest.addValue("Bearer \(securityToken)", forHTTPHeaderField: "Authorization")
        }
        
        httpRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        if let requestBody = requestBody {
            httpRequest.httpBody = requestBody
        }
        
        return httpRequest
    }
}
