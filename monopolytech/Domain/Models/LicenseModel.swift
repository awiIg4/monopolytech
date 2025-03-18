//
//  LicenseModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

struct License: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let editeur_id: String?
    
    // For preview and testing purposes
    static let placeholder = License(
        id: "LIC1",
        nom: "Super Game",
        editeur_id: "ED1"
    )
    
    // Empty state placeholders
    static let empty = License(
        id: "NONE",
        nom: "No license found",
        editeur_id: nil
    )
    
    // Helper computed properties for empty state handling
    var displayName: String {
        return nom.isEmpty ? "No license found" : nom
    }
    
    var displayEditeurId: String {
        return editeur_id ?? "No editor assigned"
    }
} 