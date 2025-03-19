//
//  AuthService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import Combine

/// Authentication request model
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

/// User model
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

/// Authentication error types
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
    
    // UserDefaults keys
    private let tokenKey = "auth.token"
    private let userKey = "auth.user"
    
    /// Private initializer for singleton
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    /// Load authentication data from storage
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
    
    /// Save authentication data to storage
    private func saveToStorage(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    /// Login method that uses the correct endpoint based on user type
    func login(email: String, password: String, userType: String) async throws -> User {
        let loginRequest = LoginRequest(email: email, motdepasse: password)
        
        // Determine endpoint based on user type
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
            
            // TODO: Remove this debug log in production
            print("JSON sent: \(String(data: requestData, encoding: .utf8) ?? "Invalid JSON")")
            
            // First, make a debug raw request to see what's happening
            let (responseData, statusCode, headerFields) = try await apiService.debugRawRequestWithHeaders(
                endpoint,
                httpMethod: "POST",
                requestBody: requestData
            )
            
            // If the status code is successful, try to extract the token from cookies
            if (200...299).contains(statusCode) {
                // Extract token from cookies
                if let accessToken = extractCookie(named: "accessToken", from: headerFields) {
                    print("Found access token in cookies: \(accessToken)")
                    
                    // Create user from token claims (if possible) or make a separate API call
                    // For now, create a placeholder user
                    let user = User(
                        id: "placeholder-id", 
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
                    print("No access token found in cookies")
                    throw AuthError.unknown("Authentication successful but no token received")
                }
            } else {
                // Handle error status codes
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                throw AuthError.unknown("Server error (\(statusCode)): \(errorMessage)")
            }
        } catch let error as AuthError {
            throw error
        } catch let error as APIError {
            // TODO: Remove these debug logs in production
            print("API Error: \(error)")
            throw AuthError.unknown("API Error: \(error.localizedDescription)")
        } catch {
            // TODO: Remove this debug log in production
            print("Non-API Error: \(error.localizedDescription)")
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    /// Logout user
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
    
    // Add this helper function to extract cookies
    private func extractCookie(named name: String, from headerFields: [AnyHashable: Any]) -> String? {
        if let cookiesStr = headerFields["Set-Cookie"] as? String {
            // Handle single cookie string
            if cookiesStr.contains("\(name)=") {
                let components = cookiesStr.components(separatedBy: ";")
                if let tokenComponent = components.first(where: { $0.contains("\(name)=") }) {
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
                if cookie.contains("\(name)=") {
                    let components = cookie.components(separatedBy: ";")
                    if let tokenComponent = components.first(where: { $0.contains("\(name)=") }) {
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
