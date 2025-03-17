//
//  APITests.swift
//  monopolytechTests
//
//  Created by eugenio on 17/03/2025.
//

import XCTest
@testable import monopolytech

final class APITests: XCTestCase {
    
    private var apiService: APIService!
    private var gameService: GameService!
    
    override func setUpWithError() throws {
        super.setUp()
        apiService = APIService()
        gameService = GameService()
        
        // Optional: Use test-specific configuration
        // apiService = APIService(baseURL: "https://back-projet-web-s7-de95e4be6979.herokuapp.com/api")
    }
    
    override func tearDownWithError() throws {
        apiService = nil
        gameService = nil
        super.tearDown()
    }
    
    // MARK: - API Service Tests
    
    func testFetchGames() async throws {
        // When
        let games = try await gameService.fetchGames()
        
        // Then
        XCTAssertFalse(games.isEmpty, "Should fetch at least one game")
        if let firstGame = games.first {
            XCTAssertNotNil(firstGame.title, "Game should have a title")
            XCTAssertGreaterThanOrEqual(firstGame.price, 0.0, "Game price should be non-negative")
        }
    }
    
    
    func testErrorHandling() async {
        // Given
        let invalidID = "non-existent-id"
        
        do {
            // When
            _ = try await gameService.fetchGame(id: invalidID)
            
            // Then
            XCTFail("Expected error for non-existent game ID")
        } catch let error as APIError {
            // Verify error is properly handled
            XCTAssertTrue(error.errorDescription?.count ?? 0 > 0, "Error should have a description")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
