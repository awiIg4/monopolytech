//
//  APITestView.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import SwiftUI

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
    }
    
    private func runTests() {
        isRunningTests = true
        testResults = "Starting tests...\n"
        
        Task {
            // Create separate results for each test to avoid mutation issues
            var gamesTestResult = ""
            var categoriesTestResult = ""
            
            // Test fetchGames
            do {
                gamesTestResult += "📱 Testing fetchGames()...\n"
                let games = try await APIService.shared.fetchGames()
                gamesTestResult += "✅ Successfully fetched \(games.count) games\n"
                if let firstGame = games.first {
                    gamesTestResult += "First game: \(firstGame.title)\n"
                    gamesTestResult += "Price: \(firstGame.price) €\n"
                }
            } catch {
                gamesTestResult += "❌ Error fetching games: \(error.localizedDescription)\n"
            }
            
            // Test fetchCategories
            do {
                categoriesTestResult += "📱 Testing fetchCategories()...\n"
                let categories = try await APIService.shared.fetchCategories()
                categoriesTestResult += "✅ Successfully fetched \(categories.count) categories\n"
                if !categories.isEmpty {
                    categoriesTestResult += "Categories: \(categories.map { $0.name }.joined(separator: ", "))\n"
                }
            } catch {
                categoriesTestResult += "❌ Error fetching categories: \(error.localizedDescription)\n"
            }
            
            // Combine results only at the end
            let finalResults = gamesTestResult + "\n-------------------\n\n" + categoriesTestResult
            
            // Update the UI on the main thread
            await MainActor.run {
                testResults = finalResults
                isRunningTests = false
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct APITestView_Previews: PreviewProvider {
    static var previews: some View {
        APITestView()
    }
}
