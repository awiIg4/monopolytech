//
//  UserModel.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation

/// Modèle représentant un utilisateur
struct User: Identifiable, Codable, Hashable {
    let id: String  // Non-optionnel, utilisera une chaîne vide si absent
    let nom: String
    let email: String
    let telephone: String
    let adresse: String?
    let type_utilisateur: String
    
    /// Utilisateur exemple pour les prévisualisations et tests
    static let placeholder = User(
        id: "USR1",
        nom: "Jean Dupont",
        email: "jean.dupont@example.com",
        telephone: "0123456789",
        adresse: "123 rue Example",
        type_utilisateur: "vendeur"
    )
    
    /// Utilisateur vide pour les états d'erreur ou d'initialisation
    static let empty = User(
        id: "",  // Chaîne vide au lieu de nil
        nom: "Aucun nom trouvé",
        email: "Aucun email trouvé",
        telephone: "Aucun téléphone trouvé",
        adresse: nil,
        type_utilisateur: "inconnu"
    )
}