//
//  APITestView.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import SwiftUI

/// Vue pour tester les connexions API
struct APITestView: View {
    @State private var testResults = "No tests run yet"
    @State private var isRunningTests = false
    
    var body: some View {
        VStack {
            Text("API Test Console")
                .font(.title)
                .padding(.top)
            
            Button(action: {
                runTests()
            }) {
                Text(isRunningTests ? "Running Tests..." : "Run API Tests")
                    .padding()
                    .background(isRunningTests ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isRunningTests)
            .padding()
            
            ScrollView {
                Text(testResults)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
        }
        .toastMessage()
    }
    
    /// Exécute une série de tests pour vérifier la connectivité avec l'API
    private func runTests() {
        isRunningTests = true
        testResults = "Starting tests...\n"
        
        Task {
            var gamesTestResult = ""
            var categoriesTestResult = ""
            var usersTestResult = ""
            
            // Test de récupération des jeux
            do {
                gamesTestResult += "Test de fetchGames()...\n"
                let games = try await GameService.shared.fetchGames()
                gamesTestResult += "Récupération réussie de \(games.count) jeux\n"
                if let firstGame = games.first {
                    gamesTestResult += "Premier jeu: \(firstGame.licence_name ?? "Inconnu")\n"
                    gamesTestResult += "Prix: \(firstGame.prix) €\n"
                }
                
                await MainActor.run {
                    NotificationService.shared.showSuccess("Jeux récupérés avec succès!")
                }
            } catch {
                gamesTestResult += "Erreur lors de la récupération des jeux: \(error.localizedDescription)\n"
                
                await MainActor.run {
                    NotificationService.shared.showError(error)
                }
            }
            
            // Test de récupération des utilisateurs
            do {
                usersTestResult += "Test du point de terminaison getUsers...\n"
                
                let (responseData, statusCode, _) = try await APIService.shared.requestWithHeaders(
                    "utilisateurs", 
                    httpMethod: "GET"
                )
                
                if (200...299).contains(statusCode) {
                    usersTestResult += "Accès réussi au point de terminaison des utilisateurs avec statut: \(statusCode)\n"
                    let responseString = String(data: responseData, encoding: .utf8) ?? "Pas de données"
                    usersTestResult += "Aperçu de la réponse: \(responseString.prefix(100))...\n"
                    
                    do {
                        let decoder = JSONDecoder()
                        let users = try decoder.decode([User].self, from: responseData)
                        usersTestResult += "Analyse réussie de \(users.count) utilisateurs\n"
                        
                        await MainActor.run {
                            NotificationService.shared.showSuccess("Utilisateurs récupérés avec succès!")
                        }
                    } catch {
                        usersTestResult += "Impossible d'analyser les données utilisateur: \(error.localizedDescription)\n"
                        usersTestResult += "Cela peut être normal si vous n'êtes pas authentifié ou si le format de réponse ne correspond pas\n"
                    }
                } else {
                    usersTestResult += "Échec d'accès au point de terminaison des utilisateurs. Statut: \(statusCode)\n"
                    usersTestResult += "C'est attendu si vous n'êtes pas authentifié - essayez de vous connecter d'abord\n"
                }
            } catch {
                usersTestResult += "Erreur lors de la récupération des utilisateurs: \(error.localizedDescription)\n"
                
                await MainActor.run {
                    NotificationService.shared.showError(error)
                }
            }
            
            // Combiner les résultats
            let finalResults = gamesTestResult + 
                              "\n-------------------\n\n" + 
                              usersTestResult
            
            // Mettre à jour l'interface utilisateur
            await MainActor.run {
                testResults = finalResults
                isRunningTests = false
            }
        }
    }
}

struct APITestView_Previews: PreviewProvider {
    static var previews: some View {
        APITestView()
    }
}
