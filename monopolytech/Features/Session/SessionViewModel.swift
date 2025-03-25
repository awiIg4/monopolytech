//
//  SessionViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour la gestion des sessions de vente
@MainActor
class SessionViewModel: ObservableObject {
    @Published var sessions: [SessionService.Session] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Formulaire pour la création/modification
    @Published var dateDebut: Date = Date()
    @Published var dateFin: Date = Date().addingTimeInterval(3600 * 3) // 3 heures plus tard
    @Published var valeurCommission: Int = 10
    @Published var commissionEnPourcentage: Bool = true
    @Published var valeurFraisDepot: Int = 5
    @Published var fraisDepotEnPourcentage: Bool = true
    
    // États pour les sheets et alertes
    @Published var showCreateSheet: Bool = false
    @Published var showEditSheet: Bool = false
    @Published var showDeleteAlert: Bool = false
    @Published var selectedSession: SessionService.Session? = nil
    
    // Service pour accéder aux données
    private let sessionService: SessionService
    
    init() {
        self.sessionService = SessionService.shared
    }
    
    /// Charge la liste des sessions depuis l'API
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedSessions = try await sessionService.getAllSessions()
            sessions = loadedSessions
        } catch {
            errorMessage = "Erreur lors du chargement des sessions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Crée une nouvelle session
    /// - Returns: True si la création a réussi, false sinon
    func createSession() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            
            let sessionData = SessionService.SessionRequest(
                date_debut: dateFormatter.string(from: dateDebut),
                date_fin: dateFormatter.string(from: dateFin),
                valeur_commission: valeurCommission,
                commission_en_pourcentage: commissionEnPourcentage,
                valeur_frais_depot: valeurFraisDepot,
                frais_depot_en_pourcentage: fraisDepotEnPourcentage
            )
            
            try await sessionService.createSession(sessionData)
            await loadSessions()
            
            isLoading = false
            return true
        } catch {
            if let apiError = error as? APIError {
                errorMessage = "Erreur: \(apiError.localizedDescription)"
            } else {
                errorMessage = "Erreur: \(error.localizedDescription)"
            }
            isLoading = false
            return false
        }
    }
    
    /// Met à jour une session existante
    /// - Returns: True si la mise à jour a réussi, false sinon
    func updateSession() async -> Bool {
        guard let selectedSession = selectedSession else {
            errorMessage = "Aucune session sélectionnée"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            
            let sessionData = SessionService.SessionRequest(
                date_debut: dateFormatter.string(from: dateDebut),
                date_fin: dateFormatter.string(from: dateFin),
                valeur_commission: valeurCommission,
                commission_en_pourcentage: commissionEnPourcentage,
                valeur_frais_depot: valeurFraisDepot,
                frais_depot_en_pourcentage: fraisDepotEnPourcentage
            )
            
            try await sessionService.updateSession(id: selectedSession.id, session: sessionData)
            await loadSessions()
            isLoading = false
            return true
        } catch {
            if let apiError = error as? APIError {
                errorMessage = "Erreur: \(apiError.localizedDescription)"
            } else {
                errorMessage = "Erreur: \(error.localizedDescription)"
            }
            isLoading = false
            return false
        }
    }
    
    /// Supprime une session par son ID
    /// - Parameter id: L'ID de la session à supprimer
    /// - Returns: True si la suppression a réussi, false sinon
    func deleteSession(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await sessionService.deleteSession(id: id)
            await loadSessions() // Recharger la liste après suppression
            isLoading = false
            return true
        } catch let error as APIError {
            // Gérer spécifiquement les erreurs API
            if case .serverError(let code, _) = error, code == 500 {
                errorMessage = "Impossible de supprimer cette session car des jeux ont déjà été vendus"
                
                // Afficher directement la notification ici
                await MainActor.run {
                    NotificationService.shared.showInfo("Impossible de supprimer cette session car des jeux ont déjà été vendus")
                }
            } else {
                errorMessage = "Erreur: \(error.localizedDescription)"
                
                // Afficher directement la notification ici
                await MainActor.run {
                    NotificationService.shared.showError(error)
                }
            }
            
            isLoading = false
            
            // Important: on charge quand même les sessions pour garder la liste visible
            await loadSessions()
            
            return false
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
            
            // Afficher directement la notification ici
            await MainActor.run {
                NotificationService.shared.showError(error)
            }
            
            isLoading = false
            
            // Important: on charge quand même les sessions pour garder la liste visible
            await loadSessions()
            
            return false
        }
    }
    
    /// Prépare le formulaire pour l'édition d'une session existante
    /// - Parameter session: La session à modifier
    func prepareForEdit(session: SessionService.Session) {
        selectedSession = session
        
        // Format date_debut and date_fin from string to Date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let startDate = formatter.date(from: session.date_debut) {
            dateDebut = startDate
        }
        
        if let endDate = formatter.date(from: session.date_fin) {
            dateFin = endDate
        }
        
        // Conversion des Int en Int (pas de conversion nécessaire)
        valeurCommission = session.valeur_commission
        commissionEnPourcentage = session.commission_en_pourcentage
        valeurFraisDepot = session.valeur_frais_depot
        fraisDepotEnPourcentage = session.frais_depot_en_pourcentage
    }
    
    /// Réinitialise le formulaire
    func clearForm() {
        dateDebut = Date()
        dateFin = Date().addingTimeInterval(3600 * 3)
        valeurCommission = 10
        commissionEnPourcentage = true
        valeurFraisDepot = 5
        fraisDepotEnPourcentage = true
        selectedSession = nil
    }
    
    /// Formate une date ISO 8601 pour l'affichage
    /// - Parameter dateString: La chaîne de date à formater
    /// - Returns: La date formatée
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy" // Format court jour/mois/année
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

