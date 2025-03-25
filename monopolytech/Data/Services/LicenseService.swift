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
    
    /// Structure pour créer ou mettre à jour une licence
    struct LicenseRequest: Encodable {
        let nom: String
        let editeur_id: Int
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
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
                
                // Convertir DTO vers le modèle License défini dans LicenseModel.swift
                func toModel() -> License {
                    return License(
                        id: String(id),
                        nom: nom,
                        editeur_id: String(editeur_id)
                    )
                }
            }
            
            let licensesDTOs: [LicenseDTO] = try await apiService.request(endpoint)
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
    
    /// Récupère une licence par son nom
    func fetchLicenseByName(name: String) async throws -> License {
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
        
        // Encodage URL pour gérer les caractères spéciaux dans le nom
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let licenseDTO: LicenseDTO = try await apiService.request("\(endpoint)/by-name/\(encodedName)")
        return licenseDTO.toModel()
    }
    
    /// Recherche des licences par terme de recherche
    /// - Parameter query: Le terme de recherche
    /// - Returns: Liste des licences correspondantes (limité à 5 selon l'API)
    func searchLicenses(query: String) async throws -> [License] {
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
        
        // Encodage URL pour gérer les caractères spéciaux dans la requête
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let licensesDTOs: [LicenseDTO] = try await apiService.request("\(endpoint)/search/\(encodedQuery)")
        return licensesDTOs.map { $0.toModel() }
    }
    
    /// Crée une nouvelle licence
    /// - Parameter license: Les données de la licence à créer
    /// - Returns: La licence créée
    func createLicense(name: String, editorId: Int) async throws -> License {
        struct LicenseDTO: Decodable {
            let id: Int
            let nom: String
            let editeur_id: Int
            
            func toModel() -> License {
                return License(
                    id: String(id),
                    nom: nom,
                    editeur_id: String(editeur_id)
                )
            }
        }
        
        let request = LicenseRequest(nom: name, editeur_id: editorId)
        let jsonData = try request.toJSONData()
        
        let licenseDTO: LicenseDTO = try await apiService.request(
            endpoint,
            httpMethod: "POST",
            requestBody: jsonData
        )
        
        return licenseDTO.toModel()
    }
    
    /// Met à jour une licence existante
    /// - Parameters:
    ///   - id: L'identifiant de la licence à mettre à jour
    ///   - name: Le nouveau nom (optionnel)
    ///   - editorId: Le nouvel identifiant d'éditeur (optionnel)
    /// - Returns: La licence mise à jour
    func updateLicense(id: String, name: String? = nil, editorId: Int? = nil) async throws -> License {
        struct LicenseDTO: Decodable {
            let id: Int
            let nom: String
            let editeur_id: Int
            
            func toModel() -> License {
                return License(
                    id: String(id),
                    nom: nom,
                    editeur_id: String(editeur_id)
                )
            }
        }
        
        // Récupérer la licence actuelle pour conserver les valeurs non modifiées
        let currentLicense = try await fetchLicense(id: id)
        
        // Créer la requête avec les valeurs mises à jour ou existantes
        var updateData: [String: Any] = [:]
        
        if let name = name {
            updateData["nom"] = name
        }
        
        // Utiliser directement l'ID d'éditeur fourni ou une valeur par défaut (0)
        // Pas besoin de convertir currentLicense.editeur_id qui est optionnel
        if let editorId = editorId {
            updateData["editeur_id"] = editorId
        }
        
        // Convertir en JSON
        let jsonData = try JSONSerialization.data(withJSONObject: updateData, options: [])
        
        // Envoyer la requête de mise à jour
        let licenseDTO: LicenseDTO = try await apiService.request(
            "\(endpoint)/\(id)",
            httpMethod: "PUT",
            requestBody: jsonData
        )
        
        return licenseDTO.toModel()
    }
    
    /// Supprime une licence
    /// - Parameter id: L'identifiant de la licence à supprimer
    /// - Returns: Message de confirmation
    func deleteLicense(id: String) async throws -> String {
        return try await apiService.request("\(endpoint)/\(id)", httpMethod: "DELETE")
    }
}
