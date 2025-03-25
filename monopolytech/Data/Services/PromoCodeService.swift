//
//  PromoCodeService.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import Foundation

/// Service pour gérer les codes promotionnels
class PromoCodeService {
    /// Instance partagée pour l'accès au service
    static let shared = PromoCodeService()
    
    private let apiService = APIService.shared
    private let endpoint = "codesPromotion"
    
    private init() {}
    
    /// Structure pour créer ou mettre à jour un code promo
    struct PromoCodeRequest: Encodable {
        let libelle: String
        let reductionPourcent: Int
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Récupère tous les codes promo
    /// - Returns: Liste des codes promo
    /// - Throws: APIError si la requête échoue
    func fetchPromoCodes() async throws -> [CodePromo] {
        // Récupérer les données brutes
        let (data, _) = try await apiService.request(
            endpoint,
            httpMethod: "GET",
            returnRawResponse: true
        )
        
        // Structure qui correspond exactement au format de l'API
        struct PromoCodeResponse: Decodable {
            let libelle: String
            let reductionPourcent: Int
            
            func toModel() -> CodePromo {
                return CodePromo(
                    id: libelle,  // Utiliser le libellé comme ID puisqu'il est unique
                    libelle: libelle,
                    reductionPourcent: Double(reductionPourcent)
                )
            }
        }
        
        // Décodage
        let decoder = JSONDecoder()
        let promoCodes = try decoder.decode([PromoCodeResponse].self, from: data)
        return promoCodes.map { $0.toModel() }
    }
    
    /// Récupère un code promo spécifique par son libellé
    /// - Parameter libelle: Libellé du code promo
    /// - Returns: Code promo correspondant
    /// - Throws: APIError si la requête échoue
    func fetchPromoCode(libelle: String) async throws -> CodePromo {
        struct PromoCodeResponse: Decodable {
            let id: Int
            let libelle: String
            let reductionPourcent: Int 
            
            func toModel() -> CodePromo {
                return CodePromo(
                    id: String(id),
                    libelle: libelle,
                    reductionPourcent: Double(reductionPourcent)
                )
            }
        }
        
        // Encodage URL pour gérer les caractères spéciaux dans le libellé
        let encodedLibelle = libelle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? libelle
        let promoCodeDTO: PromoCodeResponse = try await apiService.request("\(endpoint)/\(encodedLibelle)")
        return promoCodeDTO.toModel()
    }
    
    /// Récupère seulement la réduction associée à un code promo
    /// - Parameter codePromo: Code promo à vérifier
    /// - Returns: Pourcentage de réduction
    /// - Throws: APIError si la requête échoue
    func fetchPromoCodeReduction(codePromo: String) async throws -> Double {
        struct ReductionDTO: Decodable {
            let reduction: Int
        }
        
        // Encodage URL pour gérer les caractères spéciaux dans le code promo
        let encodedCode = codePromo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? codePromo
        let reductionDTO: ReductionDTO = try await apiService.request("\(endpoint)/\(encodedCode)")
        return Double(reductionDTO.reduction)
    }
    
    /// Recherche des codes promo par terme
    /// - Parameter query: Terme de recherche
    /// - Returns: Liste des codes promo correspondants
    /// - Throws: APIError si la requête échoue
    func searchPromoCodes(query: String) async throws -> [CodePromo] {
        struct PromoCodeDTO: Decodable {
            let id: Int
            let libelle: String
            let reductionPourcent: Int
            
            func toModel() -> CodePromo {
                return CodePromo(
                    id: String(id),
                    libelle: libelle,
                    reductionPourcent: Double(reductionPourcent)
                )
            }
        }
        
        // Encodage URL pour gérer les caractères spéciaux dans la requête
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let promoCodesDTO: [PromoCodeDTO] = try await apiService.request("\(endpoint)/search/\(encodedQuery)")
        return promoCodesDTO.map { $0.toModel() }
    }
    
    /// Crée un nouveau code promo
    /// - Parameters:
    ///   - libelle: Libellé du code promo
    ///   - reductionPourcent: Pourcentage de réduction
    /// - Returns: Code promo créé
    /// - Throws: APIError si la requête échoue
    func createPromoCode(libelle: String, reductionPourcent: Int) async throws -> CodePromo {
        let request = PromoCodeRequest(libelle: libelle, reductionPourcent: reductionPourcent)
        let jsonData = try request.toJSONData()
        
        do {
            // Récupérer les données brutes
            let (data, statusCode) = try await apiService.request(
                endpoint,
                httpMethod: "POST",
                requestBody: jsonData,
                returnRawResponse: true
            )
            
            // Vérifier que le statut est OK (2xx)
            guard (200...299).contains(statusCode) else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(statusCode, errorMessage)
                } else {
                    throw APIError.serverError(statusCode, "Erreur serveur inconnue")
                }
            }
            
            // Retourner un CodePromo basé sur les données de la requête puisque
            // nous savons que la création a réussi (statut 2xx)
            return CodePromo(
                id: libelle,
                libelle: libelle,
                reductionPourcent: Double(reductionPourcent)
            )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Met à jour un code promo existant
    /// - Parameters:
    ///   - libelle: Libellé actuel du code promo
    ///   - newLibelle: Nouveau libellé (optionnel)
    ///   - reductionPourcent: Nouveau pourcentage de réduction (optionnel)
    /// - Returns: Code promo mis à jour
    /// - Throws: APIError si la requête échoue
    func updatePromoCode(libelle: String, newLibelle: String? = nil, reductionPourcent: Int? = nil) async throws -> CodePromo {
        struct PromoCodeDTO: Decodable {
            let id: Int
            let libelle: String
            let reductionPourcent: Int
            
            func toModel() -> CodePromo {
                return CodePromo(
                    id: String(id),
                    libelle: libelle,
                    reductionPourcent: Double(reductionPourcent)
                )
            }
        }
        
        // Préparer les données pour la mise à jour
        var updateData: [String: Any] = [:]
        
        if let newLibelle = newLibelle {
            updateData["libelle"] = newLibelle
        }
        
        if let reductionPourcent = reductionPourcent {
            updateData["reductionPourcent"] = reductionPourcent
        }
        
        // Convertir en JSON
        let jsonData = try JSONSerialization.data(withJSONObject: updateData, options: [])
        
        // Encodage URL pour gérer les caractères spéciaux dans le libellé
        let encodedLibelle = libelle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? libelle
        
        // Envoyer la requête de mise à jour
        let promoCodeDTO: PromoCodeDTO = try await apiService.request(
            "\(endpoint)/\(encodedLibelle)",
            httpMethod: "PUT",
            requestBody: jsonData
        )
        
        return promoCodeDTO.toModel()
    }
    
    /// Supprime un code promo
    /// - Parameter libelle: Libellé du code promo à supprimer
    /// - Returns: Message de confirmation
    /// - Throws: APIError si la requête échoue
    func deletePromoCode(libelle: String) async throws -> String {
        // Encodage URL pour gérer les caractères spéciaux dans le libellé
        let encodedLibelle = libelle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? libelle
        
        return try await apiService.request(
            "\(endpoint)/\(encodedLibelle)",
            httpMethod: "DELETE"
        )
    }
}

