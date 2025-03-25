//
//  BuyerModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant un acheteur
struct Buyer: Identifiable, Codable, Hashable {
    let id: Int
    let nom: String
    let email: String
    let telephone: String
    let adresse: String?
    
    /// Acheteur exemple pour les prévisualisations et tests
    static let placeholder = Buyer(
        id: 1,
        nom: "Hugo Brun",
        email: "hugo@example.com",
        telephone: "0123456789",
        adresse: "123 rue Example"
    )
    
    /// Acheteur vide pour les états d'erreur ou d'initialisation
    static let empty = Buyer(
        id: -1,
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found"
    )
    
    /// Nom à afficher avec gestion des cas vides
    var displayName: String {
        return nom.isEmpty ? "No name found" : nom
    }
    
    /// Email à afficher avec gestion des cas vides
    var displayEmail: String {
        return email.isEmpty ? "No email found" : email
    }
    
    /// Téléphone à afficher avec gestion des cas vides
    var displayPhone: String {
        return telephone.isEmpty ? "No phone number" : telephone
    }
    
    /// Adresse à afficher avec gestion des cas vides
    var displayAddress: String {
        return adresse ?? "No address found"
    }
} 
