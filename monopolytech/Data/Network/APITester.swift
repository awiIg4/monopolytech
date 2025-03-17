//
//  APITester.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation
import SwiftUI

class APITester {
    static let shared = APITester()
    private let apiService = APIService.shared
    
    func testFetchGames() async {
        do {
            print("📱 Testing fetchGames()...")
            let games = try await apiService.fetchGames()
            print("✅ Successfully fetched \(games.count) games")
            print("First game: \(games.first?.title ?? "None")")
        } catch {
            print("❌ Error fetching games: \(error.localizedDescription)")
        }
    }
    
    func testFetchCategories() async {
        do {
            print("📱 Testing fetchCategories()...")
            let categories = try await apiService.fetchCategories()
            print("✅ Successfully fetched \(categories.count) categories")
            print("Categories: \(categories.map { $0.name })")
        } catch {
            print("❌ Error fetching categories: \(error.localizedDescription)")
        }
    }
    
    func testFetchGameDetails() async {
        do {
            print("📱 Testing fetchGames() first, to get an ID...")
            let games = try await apiService.fetchGames()
            
            guard let firstGame = games.first else {
                print("❌ No games available to test details")
                return
            }
            
            print("📱 Testing fetchGame(id: \(firstGame.id))...")
            let gameDetails = try await apiService.fetchGame(id: firstGame.id)
            print("✅ Successfully fetched game details for: \(gameDetails.title)")
        } catch {
            print("❌ Error fetching game details: \(error.localizedDescription)")
        }
    }
    
    func runAllTests() async {
        await testFetchGames()
        print("\n-------------------\n")
        await testFetchCategories()
        print("\n-------------------\n")
        await testFetchGameDetails()
    }
}
