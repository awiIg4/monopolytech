//
//  BilanModel.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation

struct BilanModel: Codable {
    let session: BilanSession
    let bilan: BilanDetails
    
    // Structure simplifiée de Session uniquement pour le bilan
    struct BilanSession: Codable {
        let id: Int
        let date_debut: String
        let date_fin: String
    }
    
    struct BilanDetails: Codable {
        let total_generé_par_vendeurs: String
        let total_dû_aux_vendeurs: String
        let argent_généré_pour_admin: String
    }
}
