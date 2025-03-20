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
            // Use debugRawRequest to get the raw response data first
            let (responseData, statusCode) = try await apiService.debugRawRequest(endpoint, httpMethod: "GET")
            
            // Print raw response for debugging
            print("📋 LICENSE API STATUS CODE: \(statusCode)")
            
            // Check if we got a successful response
            guard (200...299).contains(statusCode) else {
                throw APIError.serverError(statusCode, "License fetch failed with status \(statusCode)")
            }
            
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
            
            // Décoder avec notre DTO
            let decoder = JSONDecoder()
            do {
                let licensesDTOs = try decoder.decode([LicenseDTO].self, from: responseData)
                print("✅ Successfully decoded \(licensesDTOs.count) licenses")
                
                // Convertir nos DTOs en modèles domain
                let licenses = licensesDTOs.map { $0.toModel() }
                return licenses
            } catch let decodingError {
                print("❌ License decoding error details: \(decodingError)")
                throw APIError.decodingError(decodingError)
            }
        } catch {
            print("❌ License fetch error: \(error)")
            throw error
        }
    }
    
    /// Récupère une licence spécifique par ID
    func fetchLicense(id: String) async throws -> License {
        // Même approche avec DTO pour une seule licence
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
