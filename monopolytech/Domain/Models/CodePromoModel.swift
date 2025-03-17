//
//  CodePromoModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

struct CodePromo: Identifiable, Codable, Hashable {
    let id: String
    let libelle: String
    let reductionPourcent: Double
    
    // For preview and testing purposes
    static let placeholder = CodePromo(
        id: "PROMO1",
        libelle: "SPRING2024",
        reductionPourcent: 15.0
    )
    
    // Empty state placeholders
    static let empty = CodePromo(
        id: "NONE",
        libelle: "No promo code found",
        reductionPourcent: 0.0
    )
    
    // Helper computed properties for empty state handling
    var displayLibelle: String {
        return libelle.isEmpty ? "No promo code found" : libelle
    }
    
    var displayReduction: String {
        return reductionPourcent == 0.0 ? "Pas de réduction" : "\(reductionPourcent)%"
    }
} 