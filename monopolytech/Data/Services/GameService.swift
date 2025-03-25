//
//  GameService.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation

/// Service responsable des opérations liées aux jeux
class GameService {
    /// Point d'accès spécifique pour l'API des jeux
    let gameEndpoint = "jeux/"
    
    /// Service API sous-jacent utilisé pour les requêtes réseau
    private let apiService: APIService
    
    /// Instance partagée pour l'utilisation dans toute l'application
    static let shared = GameService()
    
    /// Initialise le service de jeux
    /// - Parameter apiService: Le service API à utiliser pour les requêtes
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    /// Récupère tous les jeux avec paramètres de recherche optionnels
    /// - Parameter query: Requête de recherche optionnelle pour filtrer les jeux
    /// - Returns: Tableau d'objets Game
    /// - Throws: APIError si la requête échoue
    func fetchGames(query: String? = nil) async throws -> [Game] {
        let endpoint = query != nil ? gameEndpoint + "rechercher?q=\(query!)" : gameEndpoint + "rechercher"
        
        do {
            // Définition d'un DTO qui correspond à la structure de réponse de l'API
            struct GameDTO: Decodable {
                let quantite: Int
                let prix_min: Double
                let prix_max: Double
                let licence_nom: String
                let editeur_nom: String
                
                // Conversion de la réponse vers notre modèle Game
                func toGame() -> Game {
                    return Game(
                        id: UUID().uuidString,
                        licence_id: UUID().uuidString,
                        licence_name: licence_nom,
                        prix: prix_min,
                        prix_max: prix_max,
                        quantite: quantite,
                        editeur_nom: editeur_nom,
                        statut: "available",
                        depot_id: nil,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
            }
            
            // Effectuer la requête et convertir la réponse
            let gamesDTO: [GameDTO] = try await apiService.request(endpoint)
            return gamesDTO.map { $0.toGame() }
        } catch {
            throw error
        }
    }
    
    /// Récupère un jeu spécifique par ID
    /// - Parameter id: L'ID du jeu à récupérer
    /// - Returns: Un objet Game
    /// - Throws: APIError si la requête échoue
    func fetchGame(id: String) async throws -> Game {
        return try await apiService.request("\(gameEndpoint)\(id)")
    }
    
    /// Dépose un ou plusieurs jeux pour la vente
    /// - Parameter request: Requête structurée contenant les détails des jeux
    /// - Returns: Tableau des jeux déposés
    /// - Throws: APIError si la requête échoue
    func depositGames(request: GameDepositRequest) async throws -> [Game] {
        do {
            let requestData = try JSONEncoder().encode(request)
            
            // Effectuer la requête
            let (responseData, statusCode) = try await apiService.request(
                "jeux/deposer",
                httpMethod: "POST",
                requestBody: requestData,
                returnRawResponse: true
            )
            
            // Gestion des succès
            if (200...299).contains(statusCode) {
                do {
                    let games = try JSONDecoder().decode([Game].self, from: responseData)
                    return games
                } catch {
                    do {
                        let game = try JSONDecoder().decode(Game.self, from: responseData)
                        return [game]
                    } catch {
                        // Même si nous ne pouvons pas décoder la réponse, retourner un tableau vide pour le succès
                        return []
                    }
                }
            } else {
                throw APIError.serverError(statusCode, "Échec du dépôt de jeu avec statut \(statusCode)")
            }
        } catch {
            throw error
        }
    }

    /// Méthode simplifiée pour déposer un seul jeu
    /// - Parameters:
    ///   - licenseId: ID de la licence du jeu
    ///   - price: Prix du jeu
    ///   - quantity: Nombre d'exemplaires à déposer
    ///   - sellerId: ID du vendeur
    ///   - promoCode: Code promotionnel optionnel
    /// - Returns: Tableau des jeux déposés
    /// - Throws: APIError si la requête échoue
    func depositGame(licenseId: String, price: Double, quantity: Int, sellerId: String, promoCode: String? = nil) async throws -> [Game] {
        let request = GameDepositRequest(
            licence: [Int(licenseId)!],
            prix: [price],
            quantite: [quantity],
            code_promo: promoCode,
            id_vendeur: sellerId
        )
        
        return try await depositGames(request: request)
    }

    /// Récupère les jeux qui ne sont pas encore en rayon
    /// - Returns: Liste des jeux non mis en rayon
    /// - Throws: APIError si la requête échoue
    func fetchGamesNotInSale() async throws -> [Game] {
        do {
            // Utiliser returnRawResponse pour accéder aux données brutes
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)pas_en_rayon",
                returnRawResponse: true
            )
            
            // Vérifier le code de statut
            if (200...299).contains(statusCode) {
                // Structure DTO adaptée au format de réponse réel
                struct GameDTO: Decodable {
                    let id: Int
                    let licence_id: Int
                    let prix: String // Prix en String au lieu de Double
                    let statut: String?
                    let depot_id: Int?
                    let depot: DepotDTO?
                    
                    struct DepotDTO: Decodable {
                        let id: Int
                        let vendeur_id: Int?
                        let session_id: Int?
                    }
                    
                    func toGame() -> Game {
                        // Convertir le prix String en Double
                        let priceDouble = Double(prix.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        
                        return Game(
                            id: String(id),
                            licence_id: String(licence_id),
                            licence_name: nil, // À récupérer séparément via LicenseService
                            prix: priceDouble,
                            prix_max: priceDouble,
                            quantite: 1,
                            editeur_nom: "",
                            statut: statut,
                            depot_id: depot_id != nil ? depot_id! : 0,
                            createdAt: nil,
                            updatedAt: nil
                        )
                    }
                }
                
                // Décodage direct en tableau
                do {
                    let decoder = JSONDecoder()
                    let gamesDTO = try decoder.decode([GameDTO].self, from: responseData)
                    return gamesDTO.map { $0.toGame() }
                } catch {
                    return []
                }
            } else {
                throw APIError.serverError(statusCode, "Récupération des jeux échouée")
            }
        } catch {
            throw error
        }
    }

    /// Met des jeux en rayon (change leur statut en "en vente")
    /// - Parameter gameIds: Liste des identifiants des jeux à mettre en rayon
    /// - Returns: Liste des jeux mis à jour
    /// - Throws: APIError si la requête échoue
    func putGamesForSale(gameIds: [String]) async throws -> [Game] {
        // Convertir les IDs de String à Int
        let intIds = gameIds.compactMap { Int($0) }
        
        // Préparer la requête
        let payload: [String: Any] = [
            "jeux_ids": intIds,
            "nouveau_statut": "en vente"
        ]
        
        do {
            // Encoder le payload
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            // Effectuer la requête
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)updateStatus",
                httpMethod: "PUT",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Vérifier le code de statut
            if (200...299).contains(statusCode) {
                // La réponse est un succès, mais pas forcément au format attendu
                // Créer un jeu factice basé sur les IDs envoyés pour indiquer le succès
                return gameIds.map { id in
                    Game(
                        id: id,
                        licence_id: "",
                        licence_name: "Mis en rayon avec succès",
                        prix: 0,
                        prix_max: 0,
                        quantite: 1,
                        editeur_nom: "",
                        statut: "en vente",
                        depot_id: nil,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
            } else {
                // Si la requête a échoué, lancer une erreur
                throw APIError.serverError(statusCode, String(data: responseData, encoding: .utf8) ?? "Erreur inconnue")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Achète des jeux
    /// - Parameters:
    ///   - gameIds: Liste d'IDs des jeux à acheter
    ///   - promoCode: Code promotionnel optionnel
    ///   - buyerId: ID de l'acheteur optionnel
    /// - Returns: Résultat de l'achat
    /// - Throws: APIError si la requête échoue
    func buyGames(gameIds: [String], promoCode: String? = nil, buyerId: String? = nil) async throws -> GamePurchaseResult {
        // Convertir les IDs de String à Int
        let intIds = gameIds.compactMap { Int($0) }
        
        // Préparer la requête
        var payload: [String: Any] = [
            "jeux_a_acheter": intIds
        ]
        
        if let promoCode = promoCode, !promoCode.isEmpty {
            payload["code_promo"] = promoCode
        }
        
        if let buyerId = buyerId, !buyerId.isEmpty {
            payload["acheteur"] = Int(buyerId)
        }
        
        do {
            // Encoder le payload
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            // Effectuer la requête
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)acheter",
                httpMethod: "POST",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Vérifier le code de statut
            if (200...299).contains(statusCode) {
                do {
                    if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                        // Extraire les informations de base
                        let totalAmount = json["montant_total"] as? Double ?? 0.0
                        let reduction = json["reduction"] as? Double ?? 0.0
                        
                        var purchasedGames: [PurchasedGame] = []
                        
                        // Extraire les achats
                        if let achats = json["achats"] as? [[String: Any]] {
                            for achat in achats {
                                let jeuId = achat["jeu_id"] as? Int ?? 0
                                let achatId = achat["id"] as? Int ?? 0
                                let commissionStr = achat["commission"] as? String ?? "0"
                                let commission = Double(commissionStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                                
                                // Prix estimé basé sur la commission
                                let estimatedPrice = max(commission * 5, 10.0)
                                
                                // Créer un objet PurchasedGame avec les informations disponibles
                                let purchasedGame = PurchasedGame(
                                    id: String(jeuId),
                                    name: "Jeu #\(jeuId) (Achat #\(achatId))", 
                                    price: estimatedPrice,
                                    commission: commission,
                                    vendorName: nil,
                                    editorName: nil
                                )
                                
                                purchasedGames.append(purchasedGame)
                            }
                        }
                        
                        // Calculer un montant total si non fourni
                        let calculatedTotal = purchasedGames.reduce(0) { $0 + $1.total }
                        let finalTotal = totalAmount > 0 ? totalAmount : calculatedTotal
                        
                        return GamePurchaseResult(
                            totalAmount: finalTotal,
                            discount: reduction,
                            purchasedGames: purchasedGames
                        )
                    }
                    
                    // Si on ne peut pas traiter le JSON, retourner un résultat minimal
                    return GamePurchaseResult(
                        totalAmount: 0,
                        discount: 0,
                        purchasedGames: []
                    )
                } catch {
                    return GamePurchaseResult(
                        totalAmount: 0,
                        discount: 0,
                        purchasedGames: []
                    )
                }
            } else {
                throw APIError.serverError(statusCode, String(data: responseData, encoding: .utf8) ?? "Erreur inconnue")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Récupère un jeu par son ID
    /// - Parameter id: ID du jeu
    /// - Returns: Le jeu correspondant
    /// - Throws: APIError si la requête échoue
    func getGameById(id: String) async throws -> Game {
        do {
            let game: Game = try await apiService.request("\(gameEndpoint)search/\(id)")
            return game
        } catch {
            throw error
        }
    }

    /// Récupère les jeux en vente
    /// - Returns: Liste des jeux en vente
    /// - Throws: APIError si la requête échoue
    func fetchGamesInSale() async throws -> [Game] {
        // Utiliser la fonction de recherche avec le statut "en vente"
        let params = ["statut": "en vente"]
        return try await searchGames(params: params)
    }

    /// Rechercher des jeux avec des paramètres spécifiques
    /// - Parameter params: Paramètres de recherche (dictionnaire clé-valeur)
    /// - Returns: Liste des jeux correspondant aux critères
    /// - Throws: APIError si la requête échoue
    func searchGames(params: [String: String]) async throws -> [Game] {
        // Construire la chaîne de requête à partir des paramètres
        let queryItems = params.map { key, value in 
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)" 
        }
        let queryString = queryItems.joined(separator: "&")
        
        // Utiliser la méthode fetchGames existante avec la requête construite
        return try await fetchGames(query: queryString)
    }

    /// Récupère des jeux (les marque comme récupérés)
    /// - Parameter gameIds: Liste des IDs de jeux à récupérer
    /// - Returns: Réponse de succès
    /// - Throws: APIError si la requête échoue
    func recoverGames(gameIds: [String]) async throws -> String {
        // Convertir en Int
        let intIds = gameIds.compactMap { Int($0) }
        
        // Préparation de la requête
        let payload: [String: Any] = [
            "jeux_a_recup": intIds
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            let (responseData, statusCode) = try await apiService.request(
                "\(gameEndpoint)recuperer",
                httpMethod: "POST",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            if (200...299).contains(statusCode) {
                return "Jeux récupérés avec succès"
            } else {
                throw APIError.serverError(statusCode, String(data: responseData, encoding: .utf8) ?? "Erreur inconnue")
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
            
            if (200...299).contains(statusCode) {
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
                
                // Décodage direct du tableau JSON
                let gamesDTO = try JSONDecoder().decode([GameDTO].self, from: responseData)
                return gamesDTO.map { $0.toGame() }
            } else {
                return []
            }
        } catch {
            if let apiError = error as? APIError, case .serverError(404, _) = apiError {
                return []
            }
            throw error
        }
    }
}
