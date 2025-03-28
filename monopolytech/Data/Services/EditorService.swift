//
//  EditorService.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import Foundation

/// Service pour gérer les éditeurs
class EditorService {
    
    /// Instance partagée
    static let shared = EditorService()
    
    private let apiService = APIService.shared
    private let endpoint = "editeurs"
    
    private init() {}
    
    /// Structure pour créer ou mettre à jour un éditeur
    struct EditorRequest: Encodable {
        let nom: String
        
        func toJSONData() throws -> Data {
            return try JSONEncoder().encode(self)
        }
    }
    
    /// Récupère tous les éditeurs
    /// - Returns: Liste des éditeurs
    /// - Throws: APIError si la requête échoue
    func fetchEditors() async throws -> [Editor] {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        let editorsDTO: [EditorDTO] = try await apiService.request(endpoint)
        return editorsDTO.map { $0.toModel() }
    }
    
    /// Récupère un éditeur spécifique par ID
    /// - Parameter id: Identifiant de l'éditeur
    /// - Returns: L'éditeur correspondant
    /// - Throws: APIError si la requête échoue
    func fetchEditor(id: String) async throws -> Editor {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        let editorDTO: EditorDTO = try await apiService.request("\(endpoint)/\(id)")
        return editorDTO.toModel()
    }
    
    /// Récupère un éditeur par son nom
    /// - Parameter name: Nom de l'éditeur
    /// - Returns: L'éditeur correspondant
    /// - Throws: APIError si la requête échoue
    func fetchEditorByName(name: String) async throws -> Editor {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        // Encodage URL pour gérer les caractères spéciaux dans le nom
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let editorDTO: EditorDTO = try await apiService.request("\(endpoint)/by-name/\(encodedName)")
        return editorDTO.toModel()
    }
    
    /// Recherche des éditeurs par terme de recherche
    /// - Parameter query: Le terme de recherche
    /// - Returns: Liste des éditeurs correspondants (limité à 5 selon l'API)
    /// - Throws: APIError si la requête échoue
    func searchEditors(query: String) async throws -> [Editor] {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        // Encodage URL pour gérer les caractères spéciaux dans la requête
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let editorsDTO: [EditorDTO] = try await apiService.request("\(endpoint)/search/\(encodedQuery)")
        return editorsDTO.map { $0.toModel() }
    }
    
    /// Crée un nouvel éditeur
    /// - Parameter name: Le nom de l'éditeur à créer
    /// - Returns: L'éditeur créé
    /// - Throws: APIError si la requête échoue
    func createEditor(name: String) async throws -> Editor {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        let request = EditorRequest(nom: name)
        let jsonData = try request.toJSONData()
        
        let editorDTO: EditorDTO = try await apiService.request(
            endpoint,
            httpMethod: "POST",
            requestBody: jsonData
        )
        
        return editorDTO.toModel()
    }
    
    /// Met à jour un éditeur existant
    /// - Parameters:
    ///   - id: L'identifiant de l'éditeur à mettre à jour
    ///   - name: Le nouveau nom
    /// - Returns: L'éditeur mis à jour
    /// - Throws: APIError si la requête échoue
    func updateEditor(id: String, name: String) async throws -> Editor {
        struct EditorDTO: Decodable {
            let id: Int
            let nom: String
            
            func toModel() -> Editor {
                return Editor(
                    id: String(id),
                    nom: nom
                )
            }
        }
        
        let request = EditorRequest(nom: name)
        let jsonData = try request.toJSONData()
        
        let editorDTO: EditorDTO = try await apiService.request(
            "\(endpoint)/\(id)",
            httpMethod: "PUT",
            requestBody: jsonData
        )
        
        return editorDTO.toModel()
    }
    
    /// Supprime un éditeur
    /// - Parameter id: L'identifiant de l'éditeur à supprimer
    /// - Returns: Message de confirmation
    /// - Throws: APIError si la requête échoue
    func deleteEditor(id: String) async throws -> String {
        return try await apiService.request(
            "\(endpoint)/\(id)",
            httpMethod: "DELETE"
        )
    }
}
