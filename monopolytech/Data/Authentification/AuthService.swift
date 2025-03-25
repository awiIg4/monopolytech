//
//  AuthService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import Combine

/// Modèle pour l'envoi des requêtes d'authentification
struct LoginRequest: Codable {
    let email: String
    let motdepasse: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case motdepasse
    }
}

/// Modèle pour les réponses d'authentification
struct LoginResponse: Codable {
    var token: String?
    var user: UserAuth?
}

/// Modèle utilisateur pour l'authentification
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

/// Types d'erreurs d'authentification avec messages
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

/// Service gérant l'authentification
class AuthService: ObservableObject {
    private let apiService: APIService
    
    // État utilisateur
    @Published var currentUser: UserAuth?
    @Published var isAuthenticated: Bool = false
    
    // Instance singleton
    static let shared = AuthService()
    
    // Clés de stockage
    private let tokenKey = "auth.token"
    private let userKey = "auth.user"
    private let tokenExpirationKey = "auth.tokenExpiration"
    private var tokenExpirationTimer: Timer?
    private var tokenExpirationDate: Date?
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    /// Charge l'état d'authentification sauvegardé
    private func loadFromStorage() {
        if let tokenData = UserDefaults.standard.string(forKey: tokenKey) {
            if let expirationTimestamp = UserDefaults.standard.double(forKey: tokenExpirationKey) as Double?,
               expirationTimestamp > 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                tokenExpirationDate = expirationDate
                
                if expirationDate > Date() {
                    apiService.setSecurityToken(tokenData)
                    startExpirationTimer(expiryDate: expirationDate)
                    
                    if let userData = UserDefaults.standard.data(forKey: userKey),
                       let user = try? JSONDecoder().decode(UserAuth.self, from: userData) {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                } else {
                    logout()
                }
            }
        }
    }
    
    /// Sauvegarde l'état d'authentification
    private func saveToStorage(token: String, user: UserAuth) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        if let expirationDate = extractTokenExpiration(from: token) {
            tokenExpirationDate = expirationDate
            UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: tokenExpirationKey)
            startExpirationTimer(expiryDate: expirationDate)
        }
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    /// Authentifie un utilisateur
    func login(email: String, password: String, userType: String) async throws -> UserAuth {
        let loginRequest = LoginRequest(email: email, motdepasse: password)
        
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
            
            let (responseData, statusCode, headerFields) = try await apiService.requestWithHeaders(
                endpoint,
                httpMethod: "POST",
                requestBody: requestData
            )
            
            if (200...299).contains(statusCode) {
                if let accessToken = extractCookie(named: "accessToken", from: headerFields) {
                    let user = UserAuth(
                        id: "user-\(email.hashValue)", 
                        email: email,
                        username: nil,
                        role: userType.uppercased()
                    )
                    
                    apiService.setSecurityToken(accessToken)
                    
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                    
                    saveToStorage(token: accessToken, user: user)
                    
                    return user
                } else {
                    throw AuthError.unknown("Authentification réussie mais aucun token reçu")
                }
            } else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
                throw AuthError.unknown("Erreur serveur (\(statusCode)): \(errorMessage)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    /// Déconnecte l'utilisateur
    func logout() {
        currentUser = nil
        isAuthenticated = false
        
        apiService.setSecurityToken(nil)
        
        tokenExpirationTimer?.invalidate()
        tokenExpirationTimer = nil
        
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: tokenExpirationKey)
        
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Extrait un cookie des en-têtes HTTP
    private func extractCookie(named cookieName: String, from headerFields: [AnyHashable: Any]) -> String? {
        if let cookiesStr = headerFields["Set-Cookie"] as? String {
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
    
    /// Extrait la date d'expiration d'un token JWT
    private func extractTokenExpiration(from token: String) -> Date? {
        let parts = token.components(separatedBy: ".")
        
        guard parts.count == 3,
              let payloadData = base64UrlDecode(parts[1]),
              let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
              let expTimestamp = json["exp"] as? TimeInterval else {
            return nil
        }
        
        return Date(timeIntervalSince1970: expTimestamp)
    }
    
    /// Décode une chaîne Base64Url
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Démarre le timer d'expiration du token
    private func startExpirationTimer(expiryDate: Date) {
        tokenExpirationTimer?.invalidate()
        
        let timeInterval = expiryDate.timeIntervalSinceNow
        if timeInterval > 0 {
            tokenExpirationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleTokenExpiration()
                }
            }
        } else {
            handleTokenExpiration()
        }
    }
    
    /// Gère l'expiration d'un token
    private func handleTokenExpiration() {
        logout()
        NotificationCenter.default.post(name: NSNotification.Name("TokenExpired"), object: nil)
    }
    
    /// Vérifie si le token actuel est valide
    func isTokenValid() -> Bool {
        guard isAuthenticated, 
              let expirationDate = tokenExpirationDate else {
            return false
        }
        
        return expirationDate > Date()
    }
}
