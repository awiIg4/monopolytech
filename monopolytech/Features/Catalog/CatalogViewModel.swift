//
//  CatalogViewModel.swift
//  monopolytech
//
//  Created by hugo on 18/03/2024.
//

import Foundation
import Combine

/// ViewModel pour la gestion du catalogue de jeux
class CatalogViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var currentPage = 1
    @Published private(set) var hasNextPage = true
    
    private let gameService: GameService
    private let itemsPerPage = 50
    private var currentSearchTerm: String = ""
    
    init(gameService: GameService = .shared) {
        self.gameService = gameService
    }
    
    /// Charge les jeux avec les filtres de prix spécifiés et pour la page demandée
    /// - Parameters:
    ///   - minPrice: Prix minimum (optionnel)
    ///   - maxPrice: Prix maximum (optionnel)
    ///   - page: Numéro de page à charger
    func loadGames(minPrice: Double? = nil, maxPrice: Double? = nil, page: Int = 1) {
        isLoading = true
        error = nil
        currentPage = page
        currentSearchTerm = ""
        
        Task {
            do {
                var queryParams: [String] = ["numpage=\(page)"]
                
                if let min = minPrice {
                    queryParams.append("price_min=\(min)")
                }
                if let max = maxPrice {
                    queryParams.append("price_max=\(max)")
                }
                
                let query = queryParams.joined(separator: "&")
                let fetchedGames = try await gameService.fetchGames(query: query)
                
                await MainActor.run {
                    self.games = fetchedGames
                    self.hasNextPage = !fetchedGames.isEmpty && fetchedGames.count == itemsPerPage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Recherche des jeux par nom de licence avec les filtres de prix spécifiés
    /// - Parameters:
    ///   - query: Terme de recherche
    ///   - minPrice: Prix minimum (optionnel)
    ///   - maxPrice: Prix maximum (optionnel)
    ///   - page: Numéro de page à charger
    func searchGames(query: String, minPrice: Double? = nil, maxPrice: Double? = nil, page: Int = 1) {
        guard !query.isEmpty else {
            loadGames(minPrice: minPrice, maxPrice: maxPrice, page: page)
            return
        }
        
        isLoading = true
        error = nil
        currentPage = page
        currentSearchTerm = query
        
        Task {
            do {
                let searchTerm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                var queryParams = ["numpage=\(page)"]
                queryParams.append("licence=\(searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm)")
                
                if let min = minPrice {
                    queryParams.append("price_min=\(min)")
                }
                if let max = maxPrice {
                    queryParams.append("price_max=\(max)")
                }
                
                let fullQuery = queryParams.joined(separator: "&")
                let searchResults = try await gameService.fetchGames(query: fullQuery)
                
                await MainActor.run {
                    self.games = searchResults
                    self.hasNextPage = !searchResults.isEmpty && searchResults.count == itemsPerPage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Charge la page suivante de résultats
    /// - Parameters:
    ///   - minPrice: Prix minimum (optionnel)
    ///   - maxPrice: Prix maximum (optionnel)
    func loadNextPage(minPrice: Double? = nil, maxPrice: Double? = nil) {
        currentPage += 1
        if currentSearchTerm.isEmpty {
            loadGames(minPrice: minPrice, maxPrice: maxPrice, page: currentPage)
        } else {
            searchGames(query: currentSearchTerm, minPrice: minPrice, maxPrice: maxPrice, page: currentPage)
        }
    }
    
    /// Charge la page précédente de résultats
    /// - Parameters:
    ///   - minPrice: Prix minimum (optionnel)
    ///   - maxPrice: Prix maximum (optionnel)
    func loadPreviousPage(minPrice: Double? = nil, maxPrice: Double? = nil) {
        if currentPage > 1 {
            currentPage -= 1
            if currentSearchTerm.isEmpty {
                loadGames(minPrice: minPrice, maxPrice: maxPrice, page: currentPage)
            } else {
                searchGames(query: currentSearchTerm, minPrice: minPrice, maxPrice: maxPrice, page: currentPage)
            }
        }
    }
    
    /// Retourne les jeux filtrés (cette fonction n'est plus utilisée car le filtrage est géré par l'API)
    /// - Parameters:
    ///   - minPrice: Prix minimum
    ///   - maxPrice: Prix maximum
    /// - Returns: Liste des jeux filtrés
    func filteredGames(minPrice: Double = 0, maxPrice: Double = Double.infinity) -> [Game] {
        return games
    }
    
    func selectGame(_ game: Game) {
        print("Jeu sélectionné: \(game.licence_name ?? "")")
    }
}

