//
//  SellerStatsViewModel.swift
//  monopolytech
//
//  Created by eugenio on 24/03/2025.
//

import Foundation
import Combine

class SellerStatsViewModel: ObservableObject {
    // Formulaire
    @Published var sellerEmail: String = ""
    @Published var selectedSessionId: String = ""
    
    // Données
    @Published var seller: User? = nil
    @Published var sessions: [Session] = []
    @Published var stats: SellerStats = .empty
    
    // États
    @Published var isLoading: Bool = false
    @Published var isLoadingStats: Bool = false
    @Published var isLoadingSessions: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var selectedGamesToRecover: Set<String> = []
    
    // Services
    private let sellerService = SellerService.shared
    private let sessionService = SessionService.shared
    private let gameService = GameService.shared
    
    init() {
        loadSessions()
    }
    
    /// Charge la liste des sessions
    func loadSessions() {
        isLoadingSessions = true
        
        Task {
            do {
                // Utiliser getAllSessionsAsDomainModels au lieu de getAllSessions
                let fetchedSessions : [Session] = try await sessionService.getAllSessionsAsDomainModels()
                
                await MainActor.run {
                    self.sessions = fetchedSessions // Maintenant c'est le bon type
                    self.isLoadingSessions = false
                    
                    // Sélectionner la première session par défaut
                    if let firstSession = fetchedSessions.first, let id = firstSession.id {
                        self.selectedSessionId = String(id)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de charger les sessions: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoadingSessions = false
                }
            }
        }
    }
    
    /// Recherche un vendeur par email
    func searchSeller() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let foundSeller = try await sellerService.getSellerByEmail(email: sellerEmail)
                
                await MainActor.run {
                    self.seller = foundSeller
                    self.isLoading = false
                    
                    // Charger les statistiques automatiquement si une session est sélectionnée
                    if !self.selectedSessionId.isEmpty {
                        self.loadSellerStats()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Vendeur non trouvé: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Charge les statistiques du vendeur pour la session sélectionnée
    func loadSellerStats() {
        guard let seller = seller, !selectedSessionId.isEmpty else {
            errorMessage = "Veuillez d'abord sélectionner un vendeur et une session"
            showAlert = true
            return
        }
        
        isLoadingStats = true
        
        Task {
            do {
                let sellerStats = try await sellerService.getSellerStats(
                    sessionId: selectedSessionId,
                    sellerId: seller.id
                )
                
                await MainActor.run {
                    self.stats = sellerStats
                    self.isLoadingStats = false
                    self.selectedGamesToRecover.removeAll()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de charger les statistiques: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoadingStats = false
                }
            }
        }
    }
    
    /// Réinitialise le solde du vendeur
    func resetSellerBalance() {
        guard let seller = seller, !selectedSessionId.isEmpty else {
            errorMessage = "Veuillez d'abord sélectionner un vendeur et une session"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let message = try await sellerService.resetSellerBalance(
                    sessionId: selectedSessionId,
                    sellerId: seller.id
                )
                
                await MainActor.run {
                    self.successMessage = message
                    self.showAlert = true
                    self.isLoading = false
                    
                    // Recharger les statistiques après réinitialisation
                    self.loadSellerStats()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de réinitialiser le solde: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Toggle selection d'un jeu à récupérer
    func toggleGameSelection(_ gameId: String) {
        if selectedGamesToRecover.contains(gameId) {
            selectedGamesToRecover.remove(gameId)
        } else {
            selectedGamesToRecover.insert(gameId)
        }
    }
    
    /// Récupère les jeux sélectionnés
    func recoverSelectedGames() {
        guard !selectedGamesToRecover.isEmpty else {
            errorMessage = "Aucun jeu sélectionné"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let message = try await gameService.recoverGames(
                    gameIds: Array(selectedGamesToRecover)
                )
                
                await MainActor.run {
                    self.successMessage = message
                    self.showAlert = true
                    self.isLoading = false
                    self.selectedGamesToRecover.removeAll()
                    
                    // Recharger les statistiques après récupération
                    self.loadSellerStats()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de récupérer les jeux: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Formatte une date pour l'affichage
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Date inconnue" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "dd/MM/yyyy"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}
