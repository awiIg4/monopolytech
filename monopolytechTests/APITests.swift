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
            XCTAssertNotNil(firstGame.licence_name, "Game should have a licence name")
            XCTAssertGreaterThan(firstGame.prix, 0, "Game price should be greater than 0")
        }
    }
    
    func testFetchGameDetails() async throws {
        // First get a game ID
        let games = try await gameService.fetchGames()
        guard let firstGame = games.first, let id = firstGame.id else {
            XCTFail("No games available to test")
            return
        }
        
        // When
        let gameDetails = try await gameService.fetchGame(id: id)
        
        // Then
        XCTAssertEqual(gameDetails.id, id, "Game ID should match")
        XCTAssertNotNil(gameDetails.licence_name, "Game should have a licence name")
    }
}
