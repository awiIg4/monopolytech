//
//  BilanModel.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation

struct BilanModel: Codable, Equatable {
    let session: Session
    let bilan: BilanDetails
    
    struct BilanDetails: Codable, Equatable {
        let total_generé_par_vendeurs: Double
        let total_dû_aux_vendeurs: Double
        let argent_généré_pour_admin: Double
    }
    
    // Pour la prévisualisation et les tests
    static let placeholder = BilanModel(
        session: Session.placeholder,
        bilan: BilanDetails(
            total_generé_par_vendeurs: 1000.0,
            total_dû_aux_vendeurs: 800.0,
            argent_généré_pour_admin: 200.0
        )
    )
    
    // État vide
    static let empty = BilanModel(
        session: Session.empty,
        bilan: BilanDetails(
            total_generé_par_vendeurs: 0.0,
            total_dû_aux_vendeurs: 0.0,
            argent_généré_pour_admin: 0.0
        )
    )
}
