//
//  EditorModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

struct Editor: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    
    // For preview and testing purposes
    static let placeholder = Editor(
        id: "ED1",
        nom: "Hugo Games"
    )
    
    // Empty state placeholders
    static let empty = Editor(
        id: "NONE",
        nom: "No editor found"
    )
    
    // Helper computed properties for empty state handling
    var displayName: String {
        return nom.isEmpty ? "No editor found" : nom
    }
} 