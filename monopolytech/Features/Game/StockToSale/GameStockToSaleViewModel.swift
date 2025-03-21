//
//  GameStockToSaleViewModel.swift
//  monopolytech
//
//  Created by eugenio on 28/03/2025.
//

import Foundation
import Combine

class GameStockToSaleViewModel: ObservableObject {
    // États
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Données
    @Published var games: [Game] = []
    @Published var licenseNames: [String: String] = [:] // Stockage des noms des licences par ID
    
    // Services
    private let gameService = GameService.shared
    private let licenseService = LicenseService.shared
    
    init() {
        loadGames()
    }
    
    /// Charge les jeux qui ne sont pas en rayon
    func loadGames() {
        isLoading = true
        
        Task {
            do {
                let fetchedGames = try await gameService.fetchGamesNotInSale()
                
                await MainActor.run {
                    self.games = fetchedGames
                    self.isLoading = false
                    self.loadLicenseNames() // Charge les noms des licences après avoir chargé les jeux
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de charger les jeux: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Charge les noms des licences pour tous les jeux
    private func loadLicenseNames() {
        // Récupérer un ensemble d'IDs de licences uniques
        let licenseIds = Set(games.map { $0.licence_id })
        
        for licenseId in licenseIds {
            Task {
                do {
                    let license = try await licenseService.fetchLicense(id: licenseId)
                    
                    await MainActor.run {
                        self.licenseNames[licenseId] = license.nom
                    }
                } catch {
                    print("Erreur lors du chargement de la licence \(licenseId): \(error.localizedDescription)")
                    
                    await MainActor.run {
                        self.licenseNames[licenseId] = "Licence inconnue"
                    }
                }
            }
        }
    }
    
    /// Récupère le nom d'une licence
    func getLicenseName(for game: Game) -> String {
        return licenseNames[game.licence_id] ?? "Chargement..."
    }
    
    /// Met un jeu en rayon
    func putGameForSale(_ game: Game) {
        // Correction ici pour le problème de l'optional
        guard let gameId = game.id, !gameId.isEmpty else {
            errorMessage = "Identifiant de jeu invalide"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // La correction est ici aussi pour l'expected element type
                let updatedGames = try await gameService.putGamesForSale(gameIds: [gameId])
                
                await MainActor.run {
                    // Supprimer le jeu de la liste
                    self.games.removeAll { $0.id == game.id }
                    self.successMessage = "Jeu ID \(gameId) mis en rayon avec succès"
                    self.showAlert = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors de la mise en rayon: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
}
