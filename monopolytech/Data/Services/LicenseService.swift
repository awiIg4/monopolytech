//
//  LicenseService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Service pour récupérer et gérer les licences
class LicenseService {
    static let shared = LicenseService()
    
    private let apiService = APIService.shared
    private let endpoint = "licences"
    
    private init() {}
    
    /// Récupère toutes les licences
    func fetchLicenses() async throws -> [License] {
        do {
            // Créer un DTO qui correspond à la structure exacte de l'API
            struct LicenseDTO: Decodable {
                let id: Int
                let nom: String
                let editeur_id: Int
                let editeur: EditorDTO?
                
                struct EditorDTO: Decodable {
                    let id: Int
                    let nom: String
                }
                
                // Convertir DTO vers notre modèle
                func toModel() -> License {
                    return License(
                        id: String(id),  // Convertir Int en String
                        nom: nom,
                        editeur_id: String(editeur_id)  // Convertir Int en String
                    )
                }
            }
            
            // Faire la requête et décoder directement
            let (responseData, statusCode) = try await apiService.request(endpoint, returnRawResponse: true)
            
            if !(200...299).contains(statusCode) {
                throw APIError.serverError(statusCode, "License fetch failed with status \(statusCode)")
            }
            
            // Décoder avec notre DTO
            let decoder = JSONDecoder()
            let licensesDTOs = try decoder.decode([LicenseDTO].self, from: responseData)
            
            // Convertir nos DTOs en modèles domain
            return licensesDTOs.map { $0.toModel() }
        } catch {
            throw error
        }
    }
    
    /// Récupère une licence spécifique par ID
    func fetchLicense(id: String) async throws -> License {
        struct LicenseDTO: Decodable {
            let id: Int
            let nom: String
            let editeur_id: Int
            let editeur: EditorDTO?
            
            struct EditorDTO: Decodable {
                let id: Int
                let nom: String
            }
            
            func toModel() -> License {
                return License(
                    id: String(id),
                    nom: nom,
                    editeur_id: String(editeur_id)
                )
            }
        }
        
        let licenseDTO: LicenseDTO = try await apiService.request("\(endpoint)/\(id)")
        return licenseDTO.toModel()
    }
}
