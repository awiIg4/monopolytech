//
//  CodePromoModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant un code promotionnel
struct CodePromo: Identifiable, Codable, Hashable {
    let id: String
    let libelle: String
    let reductionPourcent: Double
    
    /// Instance pour les prévisualisations et les tests
    static let placeholder = CodePromo(
        id: "PROMO1",
        libelle: "SPRING2024",
        reductionPourcent: 15.0
    )
    
    /// État vide pour gérer l'absence de données
    static let empty = CodePromo(
        id: "NONE",
        libelle: "No promo code found",
        reductionPourcent: 0.0
    )
    
    /// Propriétés calculées pour l'affichage adaptatif des données
    var displayLibelle: String {
        return libelle.isEmpty ? "No promo code found" : libelle
    }
    
    var displayReduction: String {
        return reductionPourcent == 0.0 ? "Pas de réduction" : "\(reductionPourcent)%"
    }
} 