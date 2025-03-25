//
//  SellerModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant un vendeur
struct Seller: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let email: String
    let telephone: String
    let adresse: String?
    
    /// Vendeur exemple pour les prévisualisations et tests
    static let placeholder = Seller(
        id: "SEL1",
        nom: "Hugo Brun",
        email: "hugo.seller@example.com",
        telephone: "0123456789",
        adresse: "789 rue Seller"
    )
    
    /// Vendeur vide pour les états d'erreur ou d'initialisation
    static let empty = Seller(
        id: "NONE",
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found"
    )
    
    var displayName: String {
        return nom.isEmpty ? "No name found" : nom
    }
    
    var displayEmail: String {
        return email.isEmpty ? "No email found" : email
    }
    
    var displayPhone: String {
        return telephone.isEmpty ? "No phone number" : telephone
    }
    
    var displayAddress: String {
        return adresse ?? "No address found"
    }
}