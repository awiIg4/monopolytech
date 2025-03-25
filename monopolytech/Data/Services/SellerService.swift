//
//  SellerService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

private let gameEndpoint = "jeu"

/// Service pour gérer les vendeurs
class SellerService {
    static let shared = SellerService()
    
    private let apiService = APIService.shared
    private let endpoint = "vendeurs"
    private let gameService = GameService.shared
    private let sessionService = SessionService.shared
    
    private init() {}
    
    /// Requête pour la création d'un vendeur
    struct CreateSellerRequest: Encodable {
        let nom: String
        let email: String
        let telephone: String
        let adresse: String // Adresse non optionnelle
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Créer un nouveau vendeur
    /// - Parameter seller: Les données du vendeur à créer
    /// - Returns: Le vendeur créé
    /// - Throws: APIError si la requête échoue
    func createSeller(_ seller: CreateSellerRequest) async throws -> User {
        struct SellerDTO: Decodable {
            let id: Int
            let nom: String
            let email: String
            let telephone: String?
            let adresse: String?
            
            func toModel() -> User {
                return User(
                    id: String(id),
                    nom: nom,
                    email: email,
                    telephone: telephone ?? "",
                    adresse: adresse,
                    type_utilisateur: "vendeur"
                )
            }
        }
        
        do {
            let jsonData = try seller.toJSONData()
            
            // Utiliser returnRawResponse pour accéder aux données brutes et au code de statut
            let (responseData, statusCode) = try await apiService.request(
                "\(endpoint)/register",
                httpMethod: "POST",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Pour debug: afficher la réponse brute
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            print("📩 CREATE SELLER RESPONSE [Status: \(statusCode)]:\n\(responseString)")
            
            // Si le statut est OK mais les données sont vides ou invalides
            if (200...299).contains(statusCode) {
                // Essayer de décoder la réponse complète
                do {
                    let sellerDTO = try JSONDecoder().decode(SellerDTO.self, from: responseData)
                    return sellerDTO.toModel()
                } catch {
                    print("⚠️ Impossible de décoder la réponse en tant que SellerDTO: \(error)")
                    
                    // Essayer d'extraire juste l'ID si possible
                    if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                       let id = json["id"] as? Int {
                        
                        // Construire un User avec l'ID récupéré et les données de la requête
                        return User(
                            id: String(id),  // Inchangé
                            nom: seller.nom,
                            email: seller.email,
                            telephone: seller.telephone,
                            adresse: seller.adresse,
                            type_utilisateur: "vendeur"
                        )
                    }
                    
                    // En dernier recours, renvoyer un User sans ID mais avec les données de la requête
                    return User(
                        id: "",  // Chaîne vide au lieu de nil
                        nom: seller.nom,
                        email: seller.email,
                        telephone: seller.telephone,
                        adresse: seller.adresse,
                        type_utilisateur: "vendeur"
                    )
                }
            } else {
                throw APIError.serverError(statusCode, "Création du vendeur échouée avec le statut \(statusCode): \(responseString)")
            }
        } catch {
            print("❌ Erreur lors de la création du vendeur: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Récupère un vendeur par son email
    func getSellerByEmail(email: String) async throws -> User {
        // Définir un DTO pour correspondre à la structure exacte de l'API
        struct SellerDTO: Decodable {
            let id: Int
            let nom: String
            let email: String
            let telephone: String?
            let adresse: String?
            
            // Convertir en modèle de domaine
            func toModel() -> User {
                return User(
                    id: String(id),  // Conversion explicite de Int vers String
                    nom: nom,
                    email: email,
                    telephone: telephone ?? "",
                    adresse: adresse,
                    type_utilisateur: "vendeur"  // Type d'utilisateur fixe pour un vendeur
                )
            }
        }
        
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        
        do {
            // Utiliser le DTO pour le décodage
            let sellerDTO: SellerDTO = try await apiService.request("\(endpoint)/\(encodedEmail)")
            return sellerDTO.toModel()
        } catch {
            throw error
        }
    }
    
    /// Récupère les statistiques d'un vendeur
    /// - Parameter sellerId: Identifiant du vendeur
    /// - Returns: Statistiques du vendeur
    func getSellerStats(sellerId: String) async throws -> SellerStats {
        struct SellerStatsDTO: Decodable {
            let nbJeuxVendus: Int
            let nbJeuxDeposes: Int
            let argentGagne: Double
        }
        
        do {
            let statsDTO: SellerStatsDTO = try await apiService.request("\(endpoint)/stats/\(sellerId)")
            
            // Créer une version simplifiée des statistiques avec les données disponibles
            return SellerStats(
                totalRevenueAllSessions: statsDTO.argentGagne,
                totalAmountDue: statsDTO.argentGagne / 2, // Approximation
                totalSoldGames: statsDTO.nbJeuxVendus,
                totalRevenue: statsDTO.argentGagne,
                amountDue: statsDTO.argentGagne / 2, // Approximation
                totalEarned: statsDTO.argentGagne,
                soldGames: [],
                stockGames: [],
                recuperableGames: []
            )
        } catch {
            throw error
        }
    }
    
    /// Récupère les statistiques d'un vendeur pour une session spécifique
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - sellerId: ID du vendeur
    /// - Returns: Les statistiques du vendeur
    /// - Throws: APIError si la requête échoue
    func getSellerStats(sessionId: String, sellerId: String) async throws -> SellerStats {
        do {
            // Debug: Afficher les paramètres
            print("📊 Récupération des statistiques pour session \(sessionId), vendeur \(sellerId)")
            
            // Récupérer les jeux et leur statut
            print("🎮 Récupération du stock...")
            let (stockData, stockStatusCode) = try await apiService.request(
                "\(endpoint)/stock/\(sessionId)/\(sellerId)",
                returnRawResponse: true
            )
            let stockResponseString = String(data: stockData, encoding: .utf8) ?? "Données illisibles"
            print("📊 STOCK RESPONSE [Code: \(stockStatusCode)]:\n\(stockResponseString)")
            
            // Continuer le décodage après avoir affiché les données brutes
            let allGames: [Game] = try JSONDecoder().decode([Game].self, from: stockData)
            let soldGames = allGames.filter { $0.statut == "vendu" }
            let stockGames = allGames.filter { $0.statut != "vendu" }
            
            // Récupérer les jeux récupérables (avec debug)
            print("🎲 Récupération des jeux récupérables...")
            let (recuperableData, recuperableStatusCode) = try await apiService.request(
                "\(gameEndpoint)/a_recuperer?vendeur=\(sellerId)&session=\(sessionId)",
                returnRawResponse: true
            )
            let recuperableResponseString = String(data: recuperableData, encoding: .utf8) ?? "Données illisibles"
            print("📊 RECUPERABLE GAMES RESPONSE [Code: \(recuperableStatusCode)]:\n\(recuperableResponseString)")
            
            // Décoder les jeux récupérables
            struct RecuperableGamesResponse: Decodable {
                let jeux: [Game]
            }
            let recuperableGamesResponse = try JSONDecoder().decode(RecuperableGamesResponse.self, from: recuperableData)
            let recuperableGames = recuperableGamesResponse.jeux
            
            // Récupérer la somme due (avec debug)
            print("💰 Récupération de la somme due...")
            let (amountDueData, amountDueStatusCode) = try await apiService.request(
                "\(endpoint)/sommedue/\(sessionId)/\(sellerId)",
                returnRawResponse: true
            )
            let amountDueResponseString = String(data: amountDueData, encoding: .utf8) ?? "Données illisibles"
            print("📊 AMOUNT DUE RESPONSE [Code: \(amountDueStatusCode)]:\n\(amountDueResponseString)")
            
            // Décoder la somme due
            struct AmountDueResponse: Decodable {
                let sommedue: Double
            }
            let amountDueResponse = try JSONDecoder().decode(AmountDueResponse.self, from: amountDueData)
            let amountDue = amountDueResponse.sommedue
            
            // Récupérer le montant total généré (avec debug)
            print("💰 Récupération du montant total généré...")
            let (totalEarnedData, totalEarnedStatusCode) = try await apiService.request(
                "\(endpoint)/argentgagne/\(sessionId)/\(sellerId)",
                returnRawResponse: true
            )
            let totalEarnedResponseString = String(data: totalEarnedData, encoding: .utf8) ?? "Données illisibles"
            print("📊 TOTAL EARNED RESPONSE [Code: \(totalEarnedStatusCode)]:\n\(totalEarnedResponseString)")
            
            // Décoder le montant total
            struct TotalEarnedResponse: Decodable {
                let sommegeneree: Double
            }
            let totalEarnedResponse = try JSONDecoder().decode(TotalEarnedResponse.self, from: totalEarnedData)
            let totalEarned = totalEarnedResponse.sommegeneree
            
            // Statistiques globales
            var totalRevenueAllSessions: Double = 0.0
            var totalAmountDue: Double = 0.0
            
            // Récupérer toutes les sessions
            let sessions: [Session] = try await sessionService.getAllSessionsAsDomainModels()
            
            // Pour chaque session, récupérer les montants et les additionner
            for session in sessions {
                if let sessionId = session.id {
                    do {
                        let amountDueResponse: AmountDueResponse = try await apiService.request("\(endpoint)/\(sellerId)/sommedue?session=\(String(sessionId))")
                        totalAmountDue += amountDueResponse.sommedue
                        
                        let totalEarnedResponse: TotalEarnedResponse = try await apiService.request("\(endpoint)/\(sellerId)/total?session=\(String(sessionId))")
                        totalRevenueAllSessions += totalEarnedResponse.sommegeneree
                    } catch {
                        // Ignorer les erreurs pour les sessions individuelles lors du calcul global
                        print("⚠️ Erreur lors de la récupération des stats pour la session \(sessionId): \(error)")
                    }
                }
            }
            
            return SellerStats(
                totalRevenueAllSessions: totalRevenueAllSessions,
                totalAmountDue: totalAmountDue,
                totalSoldGames: soldGames.count,
                totalRevenue: totalEarned,
                amountDue: amountDue,
                totalEarned: totalEarned,
                soldGames: soldGames,
                stockGames: stockGames,
                recuperableGames: recuperableGames
            )
        } catch {
            print("❌ ERREUR lors de la récupération des statistiques: \(error)")
            throw error
        }
    }
    
    /// Réinitialise le solde du vendeur (somme due à zéro)
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - sellerId: ID du vendeur
    /// - Returns: Message de succès
    /// - Throws: APIError si la requête échoue
    func resetSellerBalance(sessionId: String, sellerId: String) async throws -> String {
        do {
            let payload: [String: Any] = [
                "session_id": Int(sessionId) ?? 0,
                "vendeur_id": Int(sellerId) ?? 0
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            let (responseData, statusCode) = try await apiService.request(
                "\(endpoint)/sommedue/\(sessionId)/\(sellerId)",
                httpMethod: "PUT",
                requestBody: "{}".data(using: .utf8),
                returnRawResponse: true
            )
            
            if (200...299).contains(statusCode) {
                return "Solde réinitialisé avec succès"
            } else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
                throw APIError.serverError(statusCode, errorMessage)
            }
        } catch {
            throw error
        }
    }
}
