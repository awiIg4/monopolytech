//
//  LicenseService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Service for fetching and managing licenses
class LicenseService {
    static let shared = LicenseService()
    
    private let apiService = APIService.shared
    private let endpoint = "licences"
    
    private init() {}
    
    /// Get licenses with proper error handling and response transformation
    func fetchLicenses() async throws -> [License] {
        do {
            // Utiliser une structure qui correspond exactement à la réponse de l'API
            struct LicenseDTO: Decodable {
                let id: String  // Utiliser "id" au lieu de "_id"
                let nom: String
                let editeur_id: String?
                
                func toModel() -> License {
                    return License(
                        id: id,  // Ici on utilise le champ "id" du DTO
                        nom: nom,
                        editeur_id: editeur_id
                    )
                }
            }
            
            // Pour débugger, affichons la réponse brute
            let (data, statusCode) = try await apiService.debugRawRequest(endpoint)
            print("📝 Raw license data: \(String(data: data, encoding: .utf8) ?? "No data")")
            
            if !(200...299).contains(statusCode) {
                throw APIError.serverError(statusCode, "License fetch failed with status \(statusCode)")
            }
            
            let decoder = JSONDecoder()
            let licenseDTOs = try decoder.decode([LicenseDTO].self, from: data)
            return licenseDTOs.map { $0.toModel() }
        } catch {
            print("❌ License fetch error: \(error)")
            throw error
        }
    }
    
    /// Fetch a specific license by ID
    /// - Parameter id: The license ID
    /// - Returns: A single License object
    func fetchLicense(id: String) async throws -> License {
        do {
            struct LicenseDTO: Decodable {
                let id: String  // Utiliser "id" au lieu de "_id"
                let nom: String
                let editeur_id: String?
                
                func toModel() -> License {
                    return License(
                        id: id,
                        nom: nom,
                        editeur_id: editeur_id
                    )
                }
            }
            
            let licenseDTO: LicenseDTO = try await apiService.request("\(endpoint)/\(id)")
            return licenseDTO.toModel()
        } catch {
            print("❌ License fetch error: \(error)")
            throw error
        }
    }
}
