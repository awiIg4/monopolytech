//
//  AuthService.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation
import Combine

// Modèle de la requête d'authentification - correction du champ password vers motdepasse
struct LoginRequest: Codable {
    let email: String
    let motdepasse: String // Changé de 'password' à 'motdepasse' pour correspondre à l'API
    
    enum CodingKeys: String, CodingKey {
        case email
        case motdepasse // Clé correspondant au backend
    }
}

// Modèle de la réponse d'authentification
struct LoginResponse: Codable {
    let token: String
    let user: User
}

// Modèle utilisateur
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
    
    private init(apiService: APIService = .shared) {
        self.apiService = apiService
        loadFromStorage()
    }
    
    // Load saved authentication data
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
    
    // Save authentication data to storage
    private func saveToStorage(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    // Méthode de login qui utilise l'endpoint correct en fonction du type d'utilisateur
    func login(email: String, password: String, userType: String) async throws -> User {
        // Créer le bon modèle de requête avec le champ "motdepasse"
        let loginRequest = LoginRequest(email: email, motdepasse: password)
        
        // Déterminer l'endpoint en fonction du type d'utilisateur (seulement admin et gestionnaire)
        let endpoint: String
        switch userType.lowercased() {
        case "admin":
            endpoint = "administrateurs/login"
        case "gestionnaire":
            endpoint = "gestionnaires/login"
        default:
            throw AuthError.invalidCredentials // Type utilisateur non supporté
        }
        
        do {
            let requestData = try JSONEncoder().encode(loginRequest)
            
            // Log pour déboguer le JSON envoyé
            print("JSON envoyé: \(String(data: requestData, encoding: .utf8) ?? "Invalid JSON")")
            
            let loginResponse: LoginResponse = try await apiService.request(
                endpoint,
                httpMethod: "POST",
                requestBody: requestData
            )
            
            // Sauvegarder le token pour les futures requêtes
            apiService.setSecurityToken(loginResponse.token)
            
            // Mise à jour de l'état sur le thread principal
            await MainActor.run {
                self.currentUser = loginResponse.user
                self.isAuthenticated = true
            }
            
            // Persistance de l'authentification
            saveToStorage(token: loginResponse.token, user: loginResponse.user)
            
            return loginResponse.user
        } catch let error as APIError {
            print("Erreur API: \(error)")
            switch error {
            case .serverError(401, let message):
                print("Erreur 401: \(message ?? "Aucun message")")
                throw AuthError.invalidCredentials
            case .serverError(403, _):
                throw AuthError.accessDenied
            case .serverError(500...599, _):
                throw AuthError.serverError
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        } catch {
            print("Erreur non-API: \(error.localizedDescription)")
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // Déconnexion de l'utilisateur
    func logout() {
        // Vider l'état en mémoire
        currentUser = nil
        isAuthenticated = false
        
        // Vider le token du service API
        apiService.setSecurityToken(nil)
        
        // Vider le stockage
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}
