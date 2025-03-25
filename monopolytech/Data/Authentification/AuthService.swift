//
//  AuthService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import Combine

/// Modèle de requête d'authentification conforme aux exigences de l'API
struct LoginRequest: Codable {
    let email: String
    let motdepasse: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case motdepasse
    }
}

/// Modèle de réponse d'authentification
struct LoginResponse: Codable {
    var token: String?
    var user: UserAuth?
}

/// Modèle utilisateur conforme à la structure backend
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

/// Types d'erreurs d'authentification pour des messages adaptés
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

/// Service d'authentification pour gérer les sessions utilisateur
class AuthService: ObservableObject {
    private let apiService: APIService
    
    // État utilisateur
    @Published var currentUser: UserAuth?
    @Published var isAuthenticated: Bool = false
    
    // Instance singleton
    static let shared = AuthService()
    
    // Clés UserDefaults pour la persistance
    private let tokenKey = "auth.token"
    private let userKey = "auth.user"
    private let tokenExpirationKey = "auth.tokenExpiration"
    private var tokenExpirationTimer: Timer?
    private var tokenExpirationDate: Date?
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    /// Charge les données d'authentification depuis UserDefaults
    private func loadFromStorage() {
        if let tokenData = UserDefaults.standard.string(forKey: tokenKey) {
            // Vérifier si le token a expiré avant de l'utiliser
            if let expirationTimestamp = UserDefaults.standard.double(forKey: tokenExpirationKey) as Double?,
               expirationTimestamp > 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                tokenExpirationDate = expirationDate
                
                // Utiliser le token uniquement s'il est valide
                if expirationDate > Date() {
                    apiService.setSecurityToken(tokenData)
                    startExpirationTimer(expiryDate: expirationDate)
                    
                    if let userData = UserDefaults.standard.data(forKey: userKey),
                       let user = try? JSONDecoder().decode(UserAuth.self, from: userData) {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                } else {
                    // Token expiré, nettoyer le stockage
                    logout()
                }
            }
        }
    }
    
    /// Sauvegarde les données d'authentification dans UserDefaults
    private func saveToStorage(token: String, user: UserAuth) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Extraire et sauvegarder le temps d'expiration
        if let expirationDate = extractTokenExpiration(from: token) {
            tokenExpirationDate = expirationDate
            UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: tokenExpirationKey)
            startExpirationTimer(expiryDate: expirationDate)
        }
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    /// Authentifie un utilisateur avec son email et mot de passe selon son type
    func login(email: String, password: String, userType: String) async throws -> UserAuth {
        let loginRequest = LoginRequest(email: email, motdepasse: password)
        
        // Sélectionner le point d'accès selon le type d'utilisateur (admin ou gestionnaire)
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
            
            // Faire la requête d'authentification
            let (responseData, statusCode, headerFields) = try await apiService.requestWithHeaders(
                endpoint,
                httpMethod: "POST",
                requestBody: requestData
            )
            
            // Traiter l'authentification réussie
            if (200...299).contains(statusCode) {
                // Extraire le token des cookies
                if let accessToken = extractCookie(named: "accessToken", from: headerFields) {
                    // Créer l'utilisateur à partir des informations disponibles
                    let user = UserAuth(
                        id: "user-\(email.hashValue)", 
                        email: email,
                        username: nil,
                        role: userType.uppercased()
                    )
                    
                    // Sauvegarder le token pour les requêtes futures
                    apiService.setSecurityToken(accessToken)
                    
                    // Mettre à jour l'état sur le thread principal
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                    
                    // Persister l'authentification
                    saveToStorage(token: accessToken, user: user)
                    
                    return user
                } else {
                    throw AuthError.unknown("Authentification réussie mais aucun token reçu")
                }
            } else {
                // Gérer les codes d'état d'erreur
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
                throw AuthError.unknown("Erreur serveur (\(statusCode)): \(errorMessage)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    /// Déconnecte l'utilisateur actuel et efface les données de session
    func logout() {
        // Effacer l'état en mémoire
        currentUser = nil
        isAuthenticated = false
        
        // Effacer le token du service API - DOIT se produire en premier
        apiService.setSecurityToken(nil)
        
        // Annuler le timer d'expiration
        tokenExpirationTimer?.invalidate()
        tokenExpirationTimer = nil
        
        // Effacer le stockage
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: tokenExpirationKey)
        
        // Forcer le nettoyage du cache
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Extraire la valeur d'un cookie des en-têtes de réponse
    private func extractCookie(named cookieName: String, from headerFields: [AnyHashable: Any]) -> String? {
        if let cookiesStr = headerFields["Set-Cookie"] as? String {
            // Gérer une chaîne de cookie unique
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
            // Gérer un tableau de cookies
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
    
    /// Extraire l'expiration du JWT
    private func extractTokenExpiration(from token: String) -> Date? {
        // Format de token JWT: header.payload.signature
        let parts = token.components(separatedBy: ".")
        
        guard parts.count == 3,
              let payloadData = base64UrlDecode(parts[1]),
              let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
              let expTimestamp = json["exp"] as? TimeInterval else {
            return nil
        }
        
        // JWT exp est en secondes depuis l'époque
        return Date(timeIntervalSince1970: expTimestamp)
    }
    
    /// Utilitaire de décodage Base64Url
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Ajouter le padding si nécessaire
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Démarrer le timer d'expiration
    private func startExpirationTimer(expiryDate: Date) {
        // Annuler le timer existant s'il y en a un
        tokenExpirationTimer?.invalidate()
        
        let timeInterval = expiryDate.timeIntervalSinceNow
        if timeInterval > 0 {
            // Programmer le timer uniquement si l'expiration est dans le futur
            tokenExpirationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleTokenExpiration()
                }
            }
        } else {
            // Token déjà expiré
            handleTokenExpiration()
        }
    }
    
    /// Gérer l'expiration du token
    private func handleTokenExpiration() {
        // Déconnecter et notifier l'utilisateur
        logout()
        NotificationCenter.default.post(name: NSNotification.Name("TokenExpired"), object: nil)
    }
    
    /// Vérifier la validité du token
    func isTokenValid() -> Bool {
        guard isAuthenticated, 
              let expirationDate = tokenExpirationDate else {
            return false
        }
        
        return expirationDate > Date()
    }
}
