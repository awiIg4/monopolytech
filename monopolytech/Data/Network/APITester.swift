//
//  APITester.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import Foundation
import SwiftUI

/// Classe utilitaire pour tester les fonctionnalités API
class APITester {
    static let shared = APITester()
    private let gameService = GameService.shared
    
    /// Teste la récupération des jeux
    func testFetchGames() async {
        do {
            print("📱 Test de fetchGames()...")
            let games = try await gameService.fetchGames()
            print("✅ Récupération réussie de \(games.count) jeux")
            if let firstGame = games.first {
                print("Premier jeu: \(firstGame.licence_name ?? "Inconnu")")
                print("Prix: \(firstGame.prix) €")
            }
        } catch {
            print("❌ Erreur lors de la récupération des jeux: \(error.localizedDescription)")
        }
    }
    
    /// Teste la récupération des détails d'un jeu
    func testFetchGameDetails() async {
        do {
            print("📱 Test préalable de fetchGames() pour obtenir un ID...")
            let games = try await gameService.fetchGames()
            
            guard let firstGame = games.first, let id = firstGame.id else {
                print("❌ Aucun jeu disponible pour tester les détails")
                return
            }
            
            print("📱 Test de fetchGame(id: \(id))...")
            let gameDetails = try await gameService.fetchGame(id: id)
            print("✅ Récupération réussie des détails du jeu: \(gameDetails.licence_name ?? "Inconnu")")
        } catch {
            print("❌ Erreur lors de la récupération des détails du jeu: \(error.localizedDescription)")
        }
    }
    
    /// Teste l'accès à la liste des utilisateurs
    func testGetUsers() async {
        print("📱 Test du point d'accès '/utilisateurs'...")
        
        do {
            // Tente d'accéder au point d'accès des utilisateurs (le token d'authentification sera utilisé s'il est présent dans APIService)
            let (responseData, statusCode, _) = try await APIService.shared.requestWithHeaders(
                "utilisateurs", 
                httpMethod: "GET"
            )
            
            if (200...299).contains(statusCode) {
                print("✅ Accès réussi au point d'accès des utilisateurs avec statut: \(statusCode)")
                let responseString = String(data: responseData, encoding: .utf8) ?? "Pas de données"
                print("Aperçu de la réponse: \(responseString.prefix(200))...")
                
                // Tente d'analyser les données des utilisateurs
                do {
                    let decoder = JSONDecoder()
                    let users = try decoder.decode([User].self, from: responseData)
                    print("✅ Analyse réussie de \(users.count) utilisateurs")
                } catch {
                    print("⚠️ Impossible d'analyser les données des utilisateurs: \(error.localizedDescription)")
                    print("Réponse brute: \(responseString)")
                }
            } else {
                print("❌ Échec de l'accès au point d'accès des utilisateurs. Statut: \(statusCode)")
            }
        } catch {
            print("❌ Erreur lors de la récupération des utilisateurs: \(error.localizedDescription)")
        }
    }
    
    // Cette méthode peut être décommentée une fois que vous avez un CategoryService
    /*
    func testFetchCategories() async {
        do {
            print("📱 Test de fetchCategories()...")
            let categories = try await CategoryService.shared.fetchCategories()
            print("✅ Récupération réussie de \(categories.count) catégories")
            print("Catégories: \(categories.map { $0.name })")
        } catch {
            print("❌ Erreur lors de la récupération des catégories: \(error.localizedDescription)")
        }
    }
    */
    
    /// Exécute tous les tests disponibles
    func runAllTests() async {
        await testFetchGames()
        print("\n-------------------\n")
        await testFetchGameDetails()
        print("\n-------------------\n")
        await testGetUsers()
        // Décommentez lorsque CategoryService est implémenté
        // print("\n-------------------\n")
        // await testFetchCategories()
    }
}
