//
//  APIService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import SwiftUI

/// Types d'erreurs pour les requêtes API
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

/// Service central pour les communications API
class APIService {
    private let apiBaseURL: String
    private let httpSession: URLSession
    private var securityToken: String?
    
    /// Instance partagée pour l'application
    static let shared = APIService()
    
    /// Initialise le service API
    /// - Parameters:
    ///   - apiBaseURL: URL de base pour les requêtes API
    ///   - httpSession: Session HTTP utilisée pour les requêtes réseau
    init(apiBaseURL: String = "https://back-projet-web-s7-de95e4be6979.herokuapp.com/api",
         httpSession: URLSession = .shared) {
        self.apiBaseURL = apiBaseURL
        self.httpSession = httpSession
    }
    
    /// Définit le token d'authentification pour les points d'accès sécurisés
    /// - Parameter token: JWT ou autre token d'authentification
    func setSecurityToken(_ token: String?) {
        self.securityToken = token
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Effectue une requête réseau et décode la réponse
    /// - Parameters:
    ///   - endpoint: Chemin du point d'accès API (ajouté à l'URL de base)
    ///   - httpMethod: Méthode HTTP (GET, POST, PUT, DELETE, etc.)
    ///   - requestBody: Données optionnelles pour le corps de la requête
    ///   - returnRawResponse: Si vrai, renvoie les données brutes et le code de statut au lieu des données décodées
    /// - Returns: L'objet décodé de type T ou les données brutes avec le code de statut
    /// - Throws: APIError en cas d'échec de la requête
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
            
            if returnRawResponse, T.self == (Data, Int).self {
                return (data, httpResponse.statusCode) as! T
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
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
    
    /// Effectue une requête et renvoie les données brutes avec le code de statut
    /// - Parameters:
    ///   - endpoint: Chemin du point d'accès API
    ///   - httpMethod: Méthode HTTP (GET par défaut)
    ///   - requestBody: Données optionnelles pour le corps de la requête
    /// - Returns: Tuple contenant les données et le code de statut
    /// - Throws: APIError en cas d'échec
    func request(_ endpoint: String, httpMethod: String = "GET", requestBody: Data? = nil, returnRawResponse: Bool = true) async throws -> (Data, Int) {
        let request = createURLRequest(for: endpoint, httpMethod: httpMethod, requestBody: requestBody)
        
        let (data, response) = try await httpSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return (data, httpResponse.statusCode)
    }
    
    /// Effectue une requête et renvoie les données, le code de statut et les en-têtes
    /// - Parameters:
    ///   - endpoint: Chemin du point d'accès API
    ///   - httpMethod: Méthode HTTP (GET par défaut)
    ///   - requestBody: Données optionnelles pour le corps de la requête
    /// - Returns: Tuple contenant les données, le code de statut et les en-têtes HTTP
    /// - Throws: APIError en cas d'échec
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
    
    /// Crée une requête URL pour le point d'accès spécifié
    /// - Parameters:
    ///   - endpoint: Chemin du point d'accès API
    ///   - httpMethod: Méthode HTTP
    ///   - requestBody: Données optionnelles pour le corps de la requête
    /// - Returns: La requête URL configurée
    private func createURLRequest(for endpoint: String, httpMethod: String, requestBody: Data? = nil) -> URLRequest {
        guard let fullRequestURL = URL(string: "\(apiBaseURL)/\(endpoint)") else {
            fatalError("URL invalide: \(apiBaseURL)/\(endpoint)")
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
