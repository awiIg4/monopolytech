//
//  AuthService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import Combine

/// Authentication request model matching backend API requirements
struct LoginRequest: Codable {
    let email: String
    let motdepasse: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case motdepasse
    }
}

/// Authentication response model
struct LoginResponse: Codable {
    var token: String?
    var user: User?
}

/// User model that matches backend structure
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let username: String?
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case username
        case role
    }
    
    var isAdmin: Bool {
        return role == "ADMIN"
    }
    
    var isGestionnaire: Bool {
        return role == "GESTIONNAIRE"
    }
}

/// Authentication error types for user-friendly messages
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case tokenExpired
    case accessDenied
    case serverError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email ou mot de passe incorrect"
        case .tokenExpired:
            return "Votre session a expiré, veuillez vous reconnecter"
        case .accessDenied:
            return "Vous n'avez pas les droits nécessaires pour accéder à cette fonctionnalité"
        case .serverError:
            return "Une erreur serveur s'est produite. Veuillez réessayer plus tard."
        case .unknown(let message):
            return message
        }
    }
}

/// Authentication service for managing user sessions
class AuthService: ObservableObject {
    private let apiService: APIService
    
    // User state
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    // Singleton instance
    static let shared = AuthService()
    
    // UserDefaults keys for persistence
    private let tokenKey = "auth.token"
    private let userKey = "auth.user"
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    /// Load saved authentication data from UserDefaults
    private func loadFromStorage() {
        if let tokenData = UserDefaults.standard.string(forKey: tokenKey) {
            apiService.setSecurityToken(tokenData)
            
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    /// Save authentication data to UserDefaults
    private func saveToStorage(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    /// Authenticate user with email and password based on user type
    func login(email: String, password: String, userType: String) async throws -> User {
        let loginRequest = LoginRequest(email: email, motdepasse: password)
        
        // Select endpoint based on user type (admin or gestionnaire)
        let endpoint: String
        switch userType.lowercased() {
        case "admin":
            endpoint = "administrateurs/login"
        case "gestionnaire":
            endpoint = "gestionnaires/login"
        default:
            throw AuthError.invalidCredentials
        }
        
        do {
            let requestData = try JSONEncoder().encode(loginRequest)
            
            // Make authentication request
            let (responseData, statusCode, headerFields) = try await apiService.debugRawRequestWithHeaders(
                endpoint,
                httpMethod: "POST",
                requestBody: requestData
            )
            
            // Process successful authentication
            if (200...299).contains(statusCode) {
                // Extract token from cookies
                if let accessToken = extractCookie(named: "accessToken", from: headerFields) {
                    // Create user from available information
                    // In a more complete implementation, we would extract user data from JWT claims
                    let user = User(
                        id: "user-\(email.hashValue)", // Generate a deterministic ID based on email
                        email: email,
                        username: nil,
                        role: userType.uppercased()
                    )
                    
                    // Save token for future requests
                    apiService.setSecurityToken(accessToken)
                    
                    // Update state on main thread
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                    
                    // Persist authentication
                    saveToStorage(token: accessToken, user: user)
                    
                    return user
                } else {
                    throw AuthError.unknown("Authentification réussie mais aucun token reçu")
                }
            } else {
                // Handle error status codes
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
                throw AuthError.unknown("Erreur serveur (\(statusCode)): \(errorMessage)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    /// Log out the current user and clear session data
    func logout() {
        // Clear memory state
        currentUser = nil
        isAuthenticated = false
        
        // Clear API service token
        apiService.setSecurityToken(nil)
        
        // Clear storage
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    /// Extract a cookie value from response headers
    private func extractCookie(named cookieName: String, from headerFields: [AnyHashable: Any]) -> String? {
        if let cookiesStr = headerFields["Set-Cookie"] as? String {
            // Handle single cookie string
            if cookiesStr.contains("\(cookieName)=") {
                let components = cookiesStr.components(separatedBy: ";")
                if let tokenComponent = components.first(where: { $0.contains("\(cookieName)=") }) {
                    let tokenParts = tokenComponent.components(separatedBy: "=")
                    if tokenParts.count >= 2 {
                        return tokenParts[1]
                    }
                }
            }
            return nil
        } else if let cookies = headerFields["Set-Cookie"] as? [String] {
            // Handle array of cookies
            for cookie in cookies {
                if cookie.contains("\(cookieName)=") {
                    let components = cookie.components(separatedBy: ";")
                    if let tokenComponent = components.first(where: { $0.contains("\(cookieName)=") }) {
                        let tokenParts = tokenComponent.components(separatedBy: "=")
                        if tokenParts.count >= 2 {
                            return tokenParts[1]
                        }
                    }
                }
            }
        }
        return nil
    }
}
