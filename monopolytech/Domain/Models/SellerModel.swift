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
    
    /// Instance pour les prévisualisations et les tests
    static let placeholder = Seller(
        id: "seller-1",
        nom: "Jean Dupont",
        email: "jean.dupont@example.com",
        telephone: "0123456789",
        adresse: "123 Rue de la République, 34000 Montpellier"
    )
    
    /// État vide pour gérer l'absence de données
    static let empty = Seller(
        id: "",
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found"
    )
    
    /// Propriétés calculées pour l'affichage adaptatif des données
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