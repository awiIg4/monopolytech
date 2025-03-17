//
//  GameModel.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import Foundation

struct Game: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let price: Double
    let categoryId: String?
    let category: Category?
    let imageUrl: String?
    let sellerId: String?
    let sellerName: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    static let placeholder = Game(
        id: "1",
        title: "Assassin's Creed",
        description: "Action-aventure dans un univers historique ouvert",
        price: 39.99,
        categoryId: "action",
        category: Category(id: "action", name: "Action"),
        imageUrl: nil,
        sellerId: "seller1",
        sellerName: "GameStore",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    // For preview and testing purposes
    static let placeholders = [
        Game(
            id: "1",
            title: "Assassin's Creed",
            description: "Action-aventure dans un univers historique ouvert",
            price: 39.99,
            categoryId: "action",
            category: Category(id: "action", name: "Action"),
            imageUrl: nil,
            sellerId: "seller1",
            sellerName: "GameStore",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "2",
            title: "FIFA 2025",
            description: "Simulation de football avec tous les championnats",
            price: 59.99,
            categoryId: "sport",
            category: Category(id: "sport", name: "Sport"),
            imageUrl: nil,
            sellerId: "seller2",
            sellerName: "SportGames",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Game(
            id: "3",
            title: "Minecraft",
            description: "Jeu bac à sable de construction et d'aventure",
            price: 29.99,
            categoryId: "sandbox",
            category: Category(id: "sandbox", name: "Bac à sable"),
            imageUrl: nil,
            sellerId: "seller1",
            sellerName: "GameStore",
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