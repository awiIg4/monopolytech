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
    
    /// Éditeur exemple pour les prévisualisations et tests
    static let placeholder = Editor(
        id: "ED1",
        nom: "Hugo Games"
    )
    
    /// Éditeur vide pour les états d'erreur ou d'initialisation
    static let empty = Editor(
        id: "NONE",
        nom: "No editor found"
    )
    
    var displayName: String {
        return nom.isEmpty ? "No editor found" : nom
    }
} 