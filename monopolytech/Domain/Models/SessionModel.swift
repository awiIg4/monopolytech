//
//  SessionModel.swift
//  monopolytech
//
//  Created by hugo on 17/03/2024.
//

import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: Int?
    let date_debut: String
    let date_fin: String
    let valeur_commission: Double
    let commission_en_pourcentage: Bool
    let valeur_frais_depot: Double
    let frais_depot_en_pourcentage: Bool
    
    // For preview and testing purposes
    static let placeholder = Session(
        id: 1,
        date_debut: "2024-03-17",
        date_fin: "2024-12-31",
        valeur_commission: 10.0,
        commission_en_pourcentage: true,
        valeur_frais_depot: 5.0,
        frais_depot_en_pourcentage: true
    )
    
    // Empty state placeholders
    static let empty = Session(
        id: nil,
        date_debut: "No start date",
        date_fin: "No end date",
        valeur_commission: 0.0,
        commission_en_pourcentage: false,
        valeur_frais_depot: 0.0,
        frais_depot_en_pourcentage: false
    )
    
    // Helper computed properties for empty state handling
    var displayDateDebut: String {
        return date_debut.isEmpty ? "No start date" : date_debut
    }
    
    var displayDateFin: String {
        return date_fin.isEmpty ? "No end date" : date_fin
    }
    
    var displayCommission: String {
        if commission_en_pourcentage {
            return "\(valeur_commission)%"
        }
        return "\(valeur_commission)€"
    }
    
    var displayFraisDepot: String {
        if frais_depot_en_pourcentage {
            return "\(valeur_frais_depot)%"
        }
        return "\(valeur_frais_depot)€"
    }
} 