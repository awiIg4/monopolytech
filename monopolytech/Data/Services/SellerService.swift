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
    /// Instance partagée pour l'accès au service
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
            
            // Si le statut est OK mais les données sont vides ou invalides
            if (200...299).contains(statusCode) {
                // Essayer de décoder la réponse complète
                do {
                    let sellerDTO = try JSONDecoder().decode(SellerDTO.self, from: responseData)
                    return sellerDTO.toModel()
                } catch {
                    // Essayer d'extraire juste l'ID si possible
                    if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                       let id = json["id"] as? Int {
                        
                        // Construire un User avec l'ID récupéré et les données de la requête
                        return User(
                            id: String(id),
                            nom: seller.nom,
                            email: seller.email,
                            telephone: seller.telephone,
                            adresse: seller.adresse,
                            type_utilisateur: "vendeur"
                        )
                    }
                    
                    // En dernier recours, renvoyer un User sans ID mais avec les données de la requête
                    return User(
                        id: "",
                        nom: seller.nom,
                        email: seller.email,
                        telephone: seller.telephone,
                        adresse: seller.adresse,
                        type_utilisateur: "vendeur"
                    )
                }
            } else {
                throw APIError.serverError(statusCode, "Création du vendeur échouée")
            }
        } catch {
            throw error
        }
    }
    
    /// Récupère un vendeur par son email
    /// - Parameter email: Email du vendeur
    /// - Returns: Vendeur correspondant
    /// - Throws: APIError si la requête échoue
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
                    id: String(id),
                    nom: nom,
                    email: email,
                    telephone: telephone ?? "",
                    adresse: adresse,
                    type_utilisateur: "vendeur"
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
    /// - Throws: APIError si la requête échoue
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
            // 1. Récupérer les statistiques de vente par licence
            let (statsData, statsStatusCode) = try await apiService.request(
                "\(endpoint)/stats/\(sellerId)",
                returnRawResponse: true
            )
            
            // Structure pour décoder le tableau de statistiques par licence
            struct LicenceStatItem: Decodable {
                let licence_id: Int
                let quantiteVendu: Int
                let licenceNom: String
                
                enum CodingKeys: String, CodingKey {
                    case licence_id
                    case quantiteVendu
                    case licenceNom = "licence.nom"
                }
            }
            
            // Décoder comme un tableau de statistiques par licence
            let licenceStats = try JSONDecoder().decode([LicenceStatItem].self, from: statsData)
            
            // Calculer le total des jeux vendus à partir des statistiques par licence
            let totalGamesSold = licenceStats.reduce(0) { $0 + $1.quantiteVendu }
            
            // 2. Récupérer les jeux en stock pour ce vendeur dans cette session
            let (stockData, stockStatusCode) = try await apiService.request(
                "\(endpoint)/stock/\(sessionId)/\(sellerId)",
                returnRawResponse: true
            )
            
            // Structure pour décoder les jeux avec les bons types
            struct GameDTO: Decodable {
                let id: Int
                let licence_id: Int
                let prix: String
                let statut: String
                let depot_id: Int
                let createdAt: String
                let updatedAt: String
                let depot: DepotDTO
                
                struct DepotDTO: Decodable {
                    let id: Int
                    let vendeur_id: Int
                    let session_id: Int
                    let frais_depot: String
                    let date_depot: String
                    let session: SessionDTO
                    let vendeur: VendeurDTO
                    
                    struct SessionDTO: Decodable {
                        let id: Int
                        let date_debut: String
                        let date_fin: String
                        let valeur_commission: Int
                        let commission_en_pourcentage: Bool
                        let valeur_frais_depot: Int
                        let frais_depot_en_pourcentage: Bool
                    }
                    
                    struct VendeurDTO: Decodable {
                        let id: Int
                    }
                }
                
                // Convertir en modèle de domaine
                func toGame() -> Game {
                    let dateFormatter = ISO8601DateFormatter()
                    
                    return Game(
                        id: String(id),
                        licence_id: String(licence_id),
                        licence_name: "",
                        prix: Double(prix.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                        prix_max: 0.0,
                        quantite: 1,
                        editeur_nom: "",
                        statut: statut,
                        depot_id: depot_id,
                        createdAt: createdAt.isEmpty ? nil : dateFormatter.date(from: createdAt),
                        updatedAt: updatedAt.isEmpty ? nil : dateFormatter.date(from: updatedAt)
                    )
                }
            }
            
            // Décoder les jeux en stock
            let gamesDTO = try JSONDecoder().decode([GameDTO].self, from: stockData)
            let allGames = gamesDTO.map { $0.toGame() }
            let soldGames = allGames.filter { $0.statut == "vendu" }
            let stockGames = allGames.filter { $0.statut != "vendu" }
            
            // Calculer une estimation du revenu total basée sur les jeux en stock
            let estimatedRevenue = allGames.reduce(0.0) { total, game in
                return total + game.prix
            }
            
            // Variables pour les données qui peuvent être manquantes
            var recuperableGames: [Game] = []
            var amountDue: Double = 0.0
            var totalEarned: Double = 0.0
            
            // 3. Essayer de récupérer les jeux à récupérer (gestion de l'erreur 404)
            do {
                recuperableGames = try await gameService.getSellerRecuperableGames(
                    sellerId: sellerId, 
                    sessionId: sessionId
                )
            } catch {
                // Ignorer l'erreur si aucun jeu à récupérer
            }
            
            // 4. Essayer de récupérer la somme due (gestion de l'erreur 404)
            do {
                let (amountDueData, amountDueStatusCode) = try await apiService.request(
                    "\(endpoint)/sommedue/\(sessionId)/\(sellerId)",
                    returnRawResponse: true
                )
                
                if (200...299).contains(amountDueStatusCode) {
                    struct AmountDueResponse: Decodable {
                        let sommedue: String // Format string pour correspondre au JSON
                    }
                    let response = try JSONDecoder().decode(AmountDueResponse.self, from: amountDueData)
                    // Convertir la chaîne en Double après décodage
                    amountDue = Double(response.sommedue.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                }
            } catch {
                // Ignorer l'erreur si somme due non disponible
            }
            
            // 5. Essayer de récupérer le montant total généré (gestion de l'erreur 404)
            do {
                let (totalEarnedData, totalEarnedStatusCode) = try await apiService.request(
                    "\(endpoint)/argentgagne/\(sessionId)/\(sellerId)",
                    returnRawResponse: true
                )
                
                if (200...299).contains(totalEarnedStatusCode) {
                    struct TotalEarnedResponse: Decodable {
                        let sommegeneree: Double
                    }
                    let response = try JSONDecoder().decode(TotalEarnedResponse.self, from: totalEarnedData)
                    totalEarned = response.sommegeneree
                }
            } catch {
                // Ignorer l'erreur si montant généré non disponible
            }
            
            // Utiliser des estimations pour les valeurs manquantes
            if totalEarned == 0 {
                totalEarned = estimatedRevenue
            }
            
            // Construire et retourner l'objet SellerStats
            return SellerStats(
                totalRevenueAllSessions: estimatedRevenue * 1.5, // Approximation
                totalAmountDue: amountDue,
                totalSoldGames: totalGamesSold,
                totalRevenue: totalEarned,
                amountDue: amountDue,
                totalEarned: totalEarned,
                soldGames: soldGames,
                stockGames: stockGames,
                recuperableGames: recuperableGames
            )
        } catch {
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

    /// Récupère les jeux récupérables d'un vendeur
    /// - Parameters:
    ///   - sellerId: ID du vendeur
    ///   - sessionId: ID de la session
    /// - Returns: Liste des jeux récupérables
    /// - Throws: APIError si la requête échoue
    func getSellerRecuperableGames(sellerId: String, sessionId: String) async throws -> [Game] {
        do {
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)a_recuperer?vendeur=\(sellerId)&session=\(sessionId)",
                returnRawResponse: true
            )
            
            // Si réponse 200-299, essayer de décoder
            if (200...299).contains(statusCode) {
                // Structure pour le format de jeu du backend
                struct GameDTO: Decodable {
                    let id: Int
                    let licence_id: Int
                    let prix: String
                    let statut: String
                    let depot_id: Int
                    let createdAt: String?
                    let updatedAt: String?
                    let depot: DepotDTO
                    
                    struct DepotDTO: Decodable {
                        let id: Int
                        let vendeur_id: Int
                        let session_id: Int
                        let frais_depot: String
                        let date_depot: String
                        let vendeur: VendeurDTO
                        let session: SessionDTO
                        
                        struct VendeurDTO: Decodable {
                            let id: Int
                        }
                        
                        struct SessionDTO: Decodable {
                            let id: Int
                            let date_debut: String
                            let date_fin: String
                            let valeur_commission: Int
                            let commission_en_pourcentage: Bool
                            let valeur_frais_depot: Int
                            let frais_depot_en_pourcentage: Bool
                        }
                    }
                    
                    func toGame() -> Game {
                        // Conversion des dates si présentes
                        let dateFormatter = ISO8601DateFormatter()
                        let createdDate = createdAt.flatMap { dateFormatter.date(from: $0) }
                        let updatedDate = updatedAt.flatMap { dateFormatter.date(from: $0) }
                        
                        return Game(
                            id: String(id),
                            licence_id: String(licence_id),
                            licence_name: "",
                            prix: Double(prix.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                            prix_max: 0.0,
                            quantite: 1,
                            editeur_nom: "",
                            statut: statut,
                            depot_id: depot_id,
                            createdAt: createdDate,
                            updatedAt: updatedDate
                        )
                    }
                }
                
                // Décoder directement un tableau de GameDTO
                let gamesDTO = try JSONDecoder().decode([GameDTO].self, from: responseData)
                return gamesDTO.map { $0.toGame() }
            } else {
                // En cas d'erreur 404 ou autre, retourner un tableau vide
                return []
            }
        } catch {
            // Si c'est une 404, on retourne simplement un tableau vide
            if let apiError = error as? APIError, case .serverError(404, _) = apiError {
                return []
            }
            throw error
        }
    }
}
