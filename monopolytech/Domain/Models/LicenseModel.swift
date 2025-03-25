//
//  LicenseModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant une licence de jeu
struct License: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let editeur_id: String?
    
    /// Licence exemple pour les prévisualisations et tests
    static let placeholder = License(
        id: "LIC1",
        nom: "Super Game",
        editeur_id: "ED1"
    )
    
    /// Licence vide pour les états d'erreur ou d'initialisation
    static let empty = License(
        id: "NONE",
        nom: "No license found",
        editeur_id: nil
    )
    
    var displayName: String {
        return nom.isEmpty ? "No license found" : nom
    }
    
    var displayEditeurId: String {
        return editeur_id ?? "No editor assigned"
    }
} 