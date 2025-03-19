//
//  APITestView.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import SwiftUI

// TODO: Convert to a real test suite
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
        .toastMessage() // Add toast message support
    }
    
    private func runTests() {
        isRunningTests = true
        testResults = "Starting tests...\n"
        
        Task {
            // Create separate results for each test to avoid mutation issues
            var gamesTestResult = ""
            var categoriesTestResult = ""
            var usersTestResult = "" // Added variable for users test
            
            // Test fetchGames
            do {
                gamesTestResult += "📱 Testing fetchGames()...\n"
                let games = try await GameService.shared.fetchGames()
                gamesTestResult += "✅ Successfully fetched \(games.count) games\n"
                if let firstGame = games.first {
                    gamesTestResult += "First game: \(firstGame.licence_name ?? "Unknown")\n"
                    gamesTestResult += "Price: \(firstGame.prix) €\n"
                }
                
                // Show success notification
                await MainActor.run {
                    NotificationService.shared.showSuccess("Games fetched successfully!")
                }
            } catch {
                gamesTestResult += "❌ Error fetching games: \(error.localizedDescription)\n"
                
                // Show error notification
                await MainActor.run {
                    NotificationService.shared.showError(error)
                }
            }
            
            // Test getUsers - New test section for users
            do {
                usersTestResult += "📱 Testing getUsers endpoint...\n"
                
                // Call the API tester method for users
                let (responseData, statusCode, _) = try await APIService.shared.debugRawRequestWithHeaders(
                    "utilisateurs", 
                    httpMethod: "GET"
                )
                
                if (200...299).contains(statusCode) {
                    usersTestResult += "✅ Successfully accessed users endpoint with status: \(statusCode)\n"
                    let responseString = String(data: responseData, encoding: .utf8) ?? "No data"
                    usersTestResult += "Response preview: \(responseString.prefix(100))...\n"
                    
                    // Try to parse the users data
                    do {
                        let decoder = JSONDecoder()
                        let users = try decoder.decode([User].self, from: responseData)
                        usersTestResult += "✅ Successfully parsed \(users.count) users\n"
                        
                        await MainActor.run {
                            NotificationService.shared.showSuccess("Users fetched successfully!")
                        }
                    } catch {
                        usersTestResult += "⚠️ Could not parse users data: \(error.localizedDescription)\n"
                        usersTestResult += "This might be expected if you're not authenticated or if the response format doesn't match the User model\n"
                    }
                } else {
                    usersTestResult += "❌ Failed to access users endpoint. Status: \(statusCode)\n"
                    usersTestResult += "This is expected if you're not authenticated - try logging in first\n"
                }
            } catch {
                usersTestResult += "❌ Error fetching users: \(error.localizedDescription)\n"
                
                // Show error notification
                await MainActor.run {
                    NotificationService.shared.showError(error)
                }
            }
            
            // Combine results only at the end
            let finalResults = gamesTestResult + 
                              "\n-------------------\n\n" + 
                              usersTestResult +
                              "\n-------------------\n\n" + 
                              categoriesTestResult
            
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
