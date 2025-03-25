//
//  GameModel.swift
//  monopolytech
//
//  Created by hugo on 18/03/2024.
//

import Foundation

/// Modèle représentant un jeu dans le catalogue
struct Game: Identifiable, Codable, Hashable {
    let id: String?
    let licence_id: String
    let licence_name: String?
    let prix: Double
    let prix_max: Double
    let quantite: Int
    let editeur_nom: String
    let statut: String?
    let depot_id: Int?
    let createdAt: Date?
    let updatedAt: Date?
    var category: Category?
    
    /// Instance unique pour les prévisualisations et les tests
    static let placeholder = Game(
        id: "1",
        licence_id: "ac-valhalla",
        licence_name: "Assassin's Creed Valhalla",
        prix: 39.99,
        prix_max: 49.99,
        quantite: 5,
        editeur_nom: "Ubisoft",
        statut: "available",
        depot_id: 123,
        createdAt: nil,
        updatedAt: nil
    )
    
    /// Collection d'instances pour les prévisualisations et les tests
    static let placeholders = [
        Game(
            id: "1",
            licence_id: "ac-valhalla",
            licence_name: "Assassin's Creed Valhalla",
            prix: 39.99,
            prix_max: 49.99,
            quantite: 5,
            editeur_nom: "Ubisoft",
            statut: "available",
            depot_id: 123,
            createdAt: nil,
            updatedAt: nil
        ),
        Game(
            id: "2",
            licence_id: "fifa2025",
            licence_name: "FIFA 2025",
            prix: 49.99,
            prix_max: 59.99,
            quantite: 3,
            editeur_nom: "EA Sports",
            statut: "available",
            depot_id: 124,
            createdAt: nil,
            updatedAt: nil
        ),
        Game(
            id: "3",
            licence_id: "minecraft",
            licence_name: "Minecraft",
            prix: 19.99,
            prix_max: 29.99,
            quantite: 10,
            editeur_nom: "Mojang",
            statut: "available",
            depot_id: 125,
            createdAt: nil,
            updatedAt: nil
        ),
        Game(
            id: "4",
            licence_id: "fortnite",
            licence_name: "Fortnite",
            prix: 0.00,
            prix_max: 0.00,
            quantite: 1,
            editeur_nom: "Epic Games",
            statut: "available",
            depot_id: 126,
            createdAt: nil,
            updatedAt: nil
        ),
        Game(
            id: "5",
            licence_id: "gta-v",
            licence_name: "Grand Theft Auto V",
            prix: 29.99,
            prix_max: 39.99,
            quantite: 2,
            editeur_nom: "Rockstar Games",
            statut: "sold",
            depot_id: 127,
            createdAt: nil,
            updatedAt: nil
        )
    ]
}

/// Modèle représentant une catégorie de jeu
struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    
    /// Catégories prédéfinies pour les prévisualisations et les tests
    static let placeholders = [
        Category(id: "action", name: "Action"),
        Category(id: "adventure", name: "Aventure"),
        Category(id: "rpg", name: "RPG"),
        Category(id: "strategy", name: "Stratégie"),
        Category(id: "sport", name: "Sport"),
        Category(id: "simulation", name: "Simulation"),
        Category(id: "sandbox", name: "Bac à sable")
    ]
}