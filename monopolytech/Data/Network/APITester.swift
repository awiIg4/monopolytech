//
//  APITester.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation
import SwiftUI

// Classe pour tester les fonctionnalités de l'API
class APITester {
    static let shared = APITester()
    private let gameService = GameService.shared
    
    // Teste la récupération des jeux
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
    
    // Teste la récupération des détails d'un jeu
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
    
    // Teste l'accès à la liste des utilisateurs
    func testGetUsers() async {
        print("📱 Testing getUsers endpoint '/utilisateurs'...")
        
        do {
            // Test d'accès au point d'accès des utilisateurs
            let (responseData, statusCode, _) = try await APIService.shared.requestWithHeaders(
                "utilisateurs", 
                httpMethod: "GET"
            )
            
            if (200...299).contains(statusCode) {
                print("✅ Successfully accessed users endpoint with status: \(statusCode)")
                let responseString = String(data: responseData, encoding: .utf8) ?? "No data"
                print("Response preview: \(responseString.prefix(200))...")
                
                // Tentative de décodage des données
                do {
                    let decoder = JSONDecoder()
                    let users = try decoder.decode([User].self, from: responseData)
                    print("✅ Successfully parsed \(users.count) users")
                } catch {
                    print("⚠️ Could not parse users data: \(error.localizedDescription)")
                    print("Raw response: \(responseString)")
                }
            } else {
                print("❌ Failed to access users endpoint. Status: \(statusCode)")
            }
        } catch {
            print("❌ Error fetching users: \(error.localizedDescription)")
        }
    }
    
    // Exécute tous les tests disponibles
    func runAllTests() async {
        await testFetchGames()
        print("\n-------------------\n")
        await testFetchGameDetails()
        print("\n-------------------\n")
        await testGetUsers()
    }
}
