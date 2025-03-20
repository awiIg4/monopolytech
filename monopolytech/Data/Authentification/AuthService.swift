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
    var user: UserAuth?
}

/// User model that matches backend structure
struct UserAuth: Codable, Identifiable {
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
    @Published var currentUser: UserAuth?
    @Published var isAuthenticated: Bool = false
    
    // Singleton instance
    static let shared = AuthService()
    
    // UserDefaults keys for persistence
    private let tokenKey = "auth.token"
    private let userKey = "auth.user"
    private let tokenExpirationKey = "auth.tokenExpiration"
    private var tokenExpirationTimer: Timer?
    private var tokenExpirationDate: Date?
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    /// Load saved authentication data from UserDefaults
    private func loadFromStorage() {
        if let tokenData = UserDefaults.standard.string(forKey: tokenKey) {
            // Check if token is expired before using it
            if let expirationTimestamp = UserDefaults.standard.double(forKey: tokenExpirationKey) as Double?,
               expirationTimestamp > 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                tokenExpirationDate = expirationDate
                
                // Only set token if it's still valid
                if expirationDate > Date() {
                    apiService.setSecurityToken(tokenData)
                    startExpirationTimer(expiryDate: expirationDate)
                    
                    if let userData = UserDefaults.standard.data(forKey: userKey),
                       let user = try? JSONDecoder().decode(UserAuth.self, from: userData) {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                } else {
                    // Token expired, clear storage
                    logout()
                }
            }
        }
    }
    
    /// Save authentication data to UserDefaults
    private func saveToStorage(token: String, user: UserAuth) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Extract and save expiration time
        if let expirationDate = extractTokenExpiration(from: token) {
            tokenExpirationDate = expirationDate
            UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: tokenExpirationKey)
            startExpirationTimer(expiryDate: expirationDate)
        }
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    /// Authenticate user with email and password based on user type
    func login(email: String, password: String, userType: String) async throws -> UserAuth {
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
            let (responseData, statusCode, headerFields) = try await apiService.requestWithHeaders(
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
                    let user = UserAuth(
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
    
    // TODO : Check if the logout function works properly
    /// Log out the current user and clear session data
    func logout() {
        // Clear memory state
        currentUser = nil
        isAuthenticated = false
        
        // Clear API service token - MUST happen first
        apiService.setSecurityToken(nil)
        
        // Cancel expiration timer
        tokenExpirationTimer?.invalidate()
        tokenExpirationTimer = nil
        
        // Clear storage
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: tokenExpirationKey)
        
        // Force cache cleanup
        URLCache.shared.removeAllCachedResponses()
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
    
    /// Extract expiration from JWT
    private func extractTokenExpiration(from token: String) -> Date? {
        // JWT token format: header.payload.signature
        let parts = token.components(separatedBy: ".")
        
        guard parts.count == 3,
              let payloadData = base64UrlDecode(parts[1]),
              let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
              let expTimestamp = json["exp"] as? TimeInterval else {
            return nil
        }
        
        // JWT exp is in seconds since epoch
        return Date(timeIntervalSince1970: expTimestamp)
    }
    
    /// Base64Url decode helper
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Start expiration timer
    private func startExpirationTimer(expiryDate: Date) {
        // Cancel existing timer if any
        tokenExpirationTimer?.invalidate()
        
        let timeInterval = expiryDate.timeIntervalSinceNow
        if timeInterval > 0 {
            // Schedule timer only if expiration is in the future
            tokenExpirationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleTokenExpiration()
                }
            }
        } else {
            // Token already expired
            handleTokenExpiration()
        }
    }
    
    /// Handle token expiration
    private func handleTokenExpiration() {
        // Log out and notify user
        logout()
        NotificationCenter.default.post(name: NSNotification.Name("TokenExpired"), object: nil)
        
        // You can also show an alert or notification here
        print("Authentication token expired. Please log in again.")
    }
    
    /// Check token validity
    func isTokenValid() -> Bool {
        guard isAuthenticated, 
              let expirationDate = tokenExpirationDate else {
            return false
        }
        
        return expirationDate > Date()
    }
}
