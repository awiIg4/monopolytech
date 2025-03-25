//
//  EditorModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant un éditeur de jeux
struct Editor: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    
    /// Instance pour les prévisualisations et les tests
    static let placeholder = Editor(
        id: "ED1",
        nom: "Hugo Games"
    )
    
    /// État vide pour gérer l'absence de données
    static let empty = Editor(
        id: "NONE",
        nom: "No editor found"
    )
    
    /// Propriété calculée pour l'affichage adaptatif du nom
    var displayName: String {
        return nom.isEmpty ? "No editor found" : nom
    }
} 