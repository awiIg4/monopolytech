//
//  SessionViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation
import SwiftUI

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
    
    // Utilisez l'initialisation directe ou via un inject si nécessaire
    private let sessionService: SessionService
    
    init() {
        // Utilisez une autre méthode d'initialisation si le constructeur est privé
        self.sessionService = SessionService.shared // ou une autre méthode d'accès
    }
    
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedSessions = try await sessionService.getAllSessions()
            
            // Débogage: examiner le format des dates
            if let firstSession = loadedSessions.first {
                print("Format de date brut dans l'API: \(firstSession.date_debut)")
                print("Date formatée: \(formatDate(firstSession.date_debut))")
            }
            
            sessions = loadedSessions
        } catch {
            errorMessage = "Erreur lors du chargement des sessions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
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
    
    func clearForm() {
        dateDebut = Date()
        dateFin = Date().addingTimeInterval(3600 * 3)
        valeurCommission = 10
        commissionEnPourcentage = true
        valeurFraisDepot = 5
        fraisDepotEnPourcentage = true
        selectedSession = nil
    }
    
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
    
    // Ajouter cette fonction de formatage pour le débogage
    private func formaterDate(_ dateString: String) -> String {
        print("Formatage de la date: \(dateString)")
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            print("Date parsée avec succès: \(date)")
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            let result = formatter.string(from: date)
            print("Résultat du formatage: \(result)")
            return result
        }
        
        print("Échec du parsing de la date")
        return dateString
    }
}

