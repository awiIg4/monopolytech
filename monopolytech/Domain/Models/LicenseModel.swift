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
    
    /// Instance pour les prévisualisations et les tests
    static let placeholder = License(
        id: "LIC1",
        nom: "Super Game",
        editeur_id: "ED1"
    )
    
    /// État vide pour gérer l'absence de données
    static let empty = License(
        id: "NONE",
        nom: "No license found",
        editeur_id: nil
    )
    
    /// Propriété calculée pour l'affichage adaptatif du nom
    var displayName: String {
        return nom.isEmpty ? "No license found" : nom
    }
    
    /// Propriété calculée pour l'affichage adaptatif de l'éditeur
    var displayEditeurId: String {
        return editeur_id ?? "No editor assigned"
    }
} 