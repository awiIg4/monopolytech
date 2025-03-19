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
        // Set the token to nil explicitly
        self.securityToken = token
        
        // Force clear URL session cache which might retain old authentication data
        URLCache.shared.removeAllCachedResponses()
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
        let httpRequest = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        do {
            print("Security Token : ", securityToken)
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
    
    /// Debug function to make raw API requests and return unparsed data
    func debugRawRequest(
        _ endpoint: String,
        httpMethod: String = "POST",
        requestBody: Data? = nil
    ) async throws -> (Data, Int) {
        let httpRequest = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        // Print the full request for debugging
        print("REQUEST URL: \(httpRequest.url!)")
        print("REQUEST HEADERS: \(httpRequest.allHTTPHeaderFields ?? [:])")
        if let body = httpRequest.httpBody {
            print("REQUEST BODY: \(String(data: body, encoding: .utf8) ?? "Invalid body data")")
        }
        
        do {
            let (responseData, serverResponse) = try await httpSession.data(for: httpRequest)
            
            guard let httpResponse = serverResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Print the full response for debugging
            print("RESPONSE STATUS: \(httpResponse.statusCode)")
            print("RESPONSE HEADERS: \(httpResponse.allHeaderFields)")
            let responseString = String(data: responseData, encoding: .utf8) ?? "Invalid UTF-8 data"
            print("RESPONSE BODY: \(responseString)")
            
            return (responseData, httpResponse.statusCode)
        } catch {
            print("NETWORK ERROR: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    /// Debug function to make raw API requests and return unparsed data with headers
    func debugRawRequestWithHeaders(
        _ endpoint: String,
        httpMethod: String = "POST",
        requestBody: Data? = nil
    ) async throws -> (Data, Int, [AnyHashable: Any]) {
        let httpRequest = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        // Print the full request for debugging
        print("REQUEST URL: \(httpRequest.url!)")
        print("REQUEST HEADERS: \(httpRequest.allHTTPHeaderFields ?? [:])")
        if let body = httpRequest.httpBody {
            print("REQUEST BODY: \(String(data: body, encoding: .utf8) ?? "Invalid body data")")
        }
        
        do {
            let (responseData, serverResponse) = try await httpSession.data(for: httpRequest)
            
            guard let httpResponse = serverResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Print the full response for debugging
            print("RESPONSE STATUS: \(httpResponse.statusCode)")
            print("RESPONSE HEADERS: \(httpResponse.allHeaderFields)")
            let responseString = String(data: responseData, encoding: .utf8) ?? "Invalid UTF-8 data"
            print("RESPONSE BODY: \(responseString)")
            
            return (responseData, httpResponse.statusCode, httpResponse.allHeaderFields)
        } catch {
            print("NETWORK ERROR: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    /// TODO: Ensure usage or remove
    /// Empty response type for endpoints that don't return data
    struct EmptyResponse: Decodable {
    }
    
    /// Create a URL request for the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint path (will be appended to the base URL)
    ///   - httpMethod: The HTTP method (GET, POST, PUT, DELETE, etc.)
    ///   - requestBody: Optional data to send in the request body
    /// - Returns: The URL request
    private func createURLRequest(for endpoint: String, httpMethod: String, requestBody: Data? = nil) -> URLRequest {
        guard let fullRequestURL = URL(string: "\(apiBaseURL)/\(endpoint)") else {
            // Handle invalid URL error
            fatalError("Invalid URL: \(apiBaseURL)/\(endpoint)")
        }
        
        var httpRequest = URLRequest(url: fullRequestURL)
        httpRequest.httpMethod = httpMethod
        httpRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Only add Authorization header if securityToken exists
        if let securityToken = securityToken, !securityToken.isEmpty {
            httpRequest.addValue("Bearer \(securityToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Very important: Disable caching for requests that might include auth headers
        httpRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        if let requestBody = requestBody {
            httpRequest.httpBody = requestBody
        }
        
        return httpRequest
    }
}
