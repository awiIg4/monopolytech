//
//  EditorService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

class EditorService {
    
    // Singleton instance
    static let shared = EditorService()
    
    private let apiService = APIService.shared
    private let endpoint = "editeurs"
    
    private init() {}
    
    /// Fetch all editors
    func fetchEditors() async throws -> [Editor] {
        return try await apiService.request(endpoint)
    }
    
    /// Fetch a specific editor by ID
    func fetchEditor(id: String) async throws -> Editor {
        return try await apiService.request("\(endpoint)/\(id)")
    }
}
