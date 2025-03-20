//
//  APITester.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation
import SwiftUI

// TODO: Convert to a real test suite
class APITester {
    static let shared = APITester()
    private let gameService = GameService.shared
    
    func testFetchGames() async {
        do {
            print("📱 Testing fetchGames()...")
            let games = try await gameService.fetchGames()
            print("✅ Successfully fetched \(games.count) games")
            if let firstGame = games.first {
                print("First game: \(firstGame.licence_name ?? "Unknown")")
                print("Price: \(firstGame.prix) €")
            }
        } catch {
            print("❌ Error fetching games: \(error.localizedDescription)")
        }
    }
    
    func testFetchGameDetails() async {
        do {
            print("📱 Testing fetchGames() first, to get an ID...")
            let games = try await gameService.fetchGames()
            
            guard let firstGame = games.first, let id = firstGame.id else {
                print("❌ No games available to test details")
                return
            }
            
            print("📱 Testing fetchGame(id: \(id))...")
            let gameDetails = try await gameService.fetchGame(id: id)
            print("✅ Successfully fetched game details for: \(gameDetails.licence_name ?? "Unknown")")
        } catch {
            print("❌ Error fetching game details: \(error.localizedDescription)")
        }
    }
    
    // This method can be uncommented once you have a CategoryService
    /*
    func testFetchCategories() async {
        do {
            print("📱 Testing fetchCategories()...")
            let categories = try await CategoryService.shared.fetchCategories()
            print("✅ Successfully fetched \(categories.count) categories")
            print("Categories: \(categories.map { $0.name })")
        } catch {
            print("❌ Error fetching categories: \(error.localizedDescription)")
        }
    }
    */
    
    func runAllTests() async {
        await testFetchGames()
        print("\n-------------------\n")
        await testFetchGameDetails()
        // Uncomment when CategoryService is implemented
        // print("\n-------------------\n")
        // await testFetchCategories()
    }
}
