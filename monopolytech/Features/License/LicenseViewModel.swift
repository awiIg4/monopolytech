//
//  LicenseViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour la gestion des licences de jeux
@MainActor
class LicenseViewModel: ObservableObject {
    // Données
    @Published var licenses: [License] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Formulaire pour la création/modification
    @Published var licenseName: String = ""
    @Published var editorId: String = ""
    
    // États pour les sheets et alertes
    @Published var showCreateSheet: Bool = false
    @Published var showEditSheet: Bool = false
    @Published var selectedLicense: License? = nil
    
    private let licenseService = LicenseService.shared
    private let editorService = EditorService.shared
    
    // Liste des éditeurs pour le sélecteur
    @Published var editors: [Editor] = []
    
    init() {
        Task {
            await loadLicenses()
            await loadEditors()
        }
    }
    
    /// Charge la liste des licences depuis l'API
    func loadLicenses() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedLicenses = try await licenseService.fetchLicenses()
            licenses = loadedLicenses
        } catch {
            errorMessage = "Erreur lors du chargement des licences: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
        }
        
        isLoading = false
    }
    
    /// Charge la liste des éditeurs pour le sélecteur d'éditeurs
    func loadEditors() async {
        do {
            editors = try await editorService.fetchEditors()
        } catch {
            NotificationService.shared.showError(error)
        }
    }
    
    /// Crée une nouvelle licence avec le nom et l'éditeur spécifiés
    /// - Returns: True si la création a réussi, false sinon
    func createLicense() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let editorIdInt = Int(editorId) else {
                errorMessage = "L'ID de l'éditeur doit être un nombre valide"
                NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "L'ID de l'éditeur doit être un nombre valide"
                ]))
                isLoading = false
                return false
            }
            
            _ = try await licenseService.createLicense(name: licenseName, editorId: editorIdInt)
            await loadLicenses()
            clearForm()
            isLoading = false
            
            return true
        } catch {
            errorMessage = "Erreur lors de la création de la licence: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
            isLoading = false
            return false
        }
    }
    
    /// Met à jour une licence existante
    /// - Returns: True si la mise à jour a réussi, false sinon
    func updateLicense() async -> Bool {
        guard let selectedLicense = selectedLicense else {
            errorMessage = "Aucune licence sélectionnée"
            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Aucune licence sélectionnée"
            ]))
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let editorIdInt = editorId.isEmpty ? nil : Int(editorId)
            
            _ = try await licenseService.updateLicense(
                id: selectedLicense.id,
                name: licenseName.isEmpty ? nil : licenseName,
                editorId: editorIdInt
            )
            
            await loadLicenses()
            isLoading = false
            
            return true
        } catch {
            errorMessage = "Erreur lors de la mise à jour de la licence: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime une licence par son ID
    /// - Parameter id: L'ID de la licence à supprimer
    /// - Returns: True si la suppression a réussi, false sinon
    func deleteLicense(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await licenseService.deleteLicense(id: id)
            await loadLicenses()
            isLoading = false
            
            return true
        } catch let error as APIError {
            // Format spécifique pour les erreurs API pour une meilleure lisibilité
            if case .serverError(let code, let message) = error {
                if code == 409 || code == 400 {
                    // Erreurs logiques métier (conflit, validation)
                    errorMessage = "Impossible de supprimer cette licence : \(message)"
                } else if code == 403 {
                    errorMessage = "Vous n'avez pas les droits pour supprimer cette licence"
                } else {
                    errorMessage = "Erreur serveur : \(message)"
                }
            } else {
                errorMessage = "Erreur : \(error.localizedDescription)"
            }
            
            // Recharger quand même la liste pour que l'UI reste utilisable
            await loadLicenses()
            
            isLoading = false
            return false
        } catch {
            // Erreurs génériques - simplifiées et plus lisibles
            errorMessage = "Impossible de supprimer cette licence"
            
            // Recharger quand même la liste pour que l'UI reste utilisable
            await loadLicenses()
            
            isLoading = false
            return false
        }
    }
    
    /// Prépare le formulaire pour l'édition d'une licence existante
    /// - Parameter license: La licence à modifier
    func prepareForEdit(license: License) {
        selectedLicense = license
        licenseName = license.nom
        editorId = license.editeur_id ?? ""
    }
    
    /// Réinitialise le formulaire
    func clearForm() {
        licenseName = ""
        editorId = ""
        selectedLicense = nil
    }
}

