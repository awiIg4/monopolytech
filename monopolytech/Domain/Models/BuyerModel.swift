//
//  BuyerModel.swift
//  monopolytech
//
//  Created by hugo on 17/03/2024.
//

import Foundation

struct Buyer: Identifiable, Codable, Hashable {
    let id: Int
    let nom: String
    let email: String
    let telephone: String
    let adresse: String?
    
    // For preview and testing purposes
    static let placeholder = Buyer(
        id: 1,
        nom: "Hugo Brun",
        email: "hugo@example.com",
        telephone: "0123456789",
        adresse: "123 rue Example"
    )
    
    // Empty state placeholders
    static let empty = Buyer(
        id: -1,
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found"
    )
    
    // Helper computed properties for empty state handling
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
        return adresse.isEmpty ? "No address found" : adresse
    }
} 