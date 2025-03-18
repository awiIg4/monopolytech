//
//  GameModel.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation

struct Game: Identifiable, Codable, Hashable {
    let id: String?
    let licence_id: String
    let licence_name: String?
    let prix: Double
    let statut: String?
    let depot_id: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
    // For previews and tests
    static let placeholder = Game(
        id: "1",
        licence_id: "ac-valhalla",
        licence_name: "Assassin's Creed Valhalla",
        prix: 39.99,
        statut: "available",
        depot_id: 123,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let placeholders = [
        Game(
            id: "1",
            licence_id: "ac-valhalla",
            licence_name: "Assassin's Creed Valhalla",
            prix: 39.99,
            statut: "available",
            depot_id: 123,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "2",
            licence_id: "fifa2025",
            licence_name: "FIFA 2025",
            prix: 59.99,
            statut: "available",
            depot_id: 124,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "3",
            licence_id: "minecraft",
            licence_name: "Minecraft",
            prix: 29.99,
            statut: "available",
            depot_id: 125,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "4",
            licence_id: "fortnite",
            licence_name: "Fortnite",
            prix: 0.00,
            statut: "available",
            depot_id: 126,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "5",
            licence_id: "gta-v",
            licence_name: "Grand Theft Auto V",
            prix: 29.99,
            statut: "sold",
            depot_id: 127,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    
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
