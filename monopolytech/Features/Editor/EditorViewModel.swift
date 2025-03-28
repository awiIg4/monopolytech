//
//  EditorViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour la gestion des éditeurs
@MainActor
class EditorViewModel: ObservableObject {
    // Données
    @Published var editors: [Editor] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Formulaire pour la création/modification
    @Published var editorName: String = ""
    
    // États pour les sheets et alertes
    @Published var showCreateSheet: Bool = false
    @Published var showEditSheet: Bool = false
    @Published var selectedEditor: Editor? = nil
    
    private let editorService = EditorService.shared
    
    init() {
        Task {
            await loadEditors()
        }
    }
    
    /// Charge la liste des éditeurs depuis l'API
    func loadEditors() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedEditors = try await editorService.fetchEditors()
            editors = loadedEditors
        } catch {
            errorMessage = "Erreur lors du chargement des éditeurs: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
        }
        
        isLoading = false
    }
    
    /// Crée un nouvel éditeur avec le nom spécifié
    /// - Returns: True si la création a réussi, false sinon
    func createEditor() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await editorService.createEditor(name: editorName)
            await loadEditors()
            clearForm()
            isLoading = false
            
            return true
        } catch {
            errorMessage = "Erreur lors de la création de l'éditeur: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
            isLoading = false
            return false
        }
    }
    
    /// Met à jour l'éditeur sélectionné avec le nouveau nom
    /// - Returns: True si la mise à jour a réussi, false sinon
    func updateEditor() async -> Bool {
        guard let selectedEditor = selectedEditor else {
            errorMessage = "Aucun éditeur sélectionné"
            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Aucun éditeur sélectionné"
            ]))
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await editorService.updateEditor(
                id: selectedEditor.id,
                name: editorName
            )
            
            await loadEditors()
            isLoading = false
            
            return true
        } catch {
            errorMessage = "Erreur lors de la mise à jour de l'éditeur: \(error.localizedDescription)"
            NotificationService.shared.showError(error)
            isLoading = false
            return false
        }
    }
    
    /// Supprime un éditeur par son ID
    /// - Parameter id: L'ID de l'éditeur à supprimer
    /// - Returns: True si la suppression a réussi, false sinon
    func deleteEditor(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await editorService.deleteEditor(id: id)
            await loadEditors()
            isLoading = false
            
            return true
        } catch let error as APIError {
            // Format spécifique pour les erreurs API pour une meilleure lisibilité
            if case .serverError(let code, let message) = error {
                if code == 409 || code == 400 {
                    // Erreurs logiques métier (conflit, validation)
                    errorMessage = "Impossible de supprimer cet éditeur : \(message)"
                } else if code == 403 {
                    errorMessage = "Vous n'avez pas les droits pour supprimer cet éditeur"
                } else {
                    errorMessage = "Erreur serveur : \(message)"
                }
            } else {
                errorMessage = "Erreur : \(error.localizedDescription)"
            }
            
            // Recharger quand même la liste pour que l'UI reste utilisable
            await loadEditors()
            
            isLoading = false
            return false
        } catch {
            // Erreurs génériques - simplifiées et plus lisibles
            errorMessage = "Impossible de supprimer cet éditeur"
            
            // Recharger quand même la liste pour que l'UI reste utilisable
            await loadEditors()
            
            isLoading = false
            return false
        }
    }
    
    /// Prépare le formulaire pour l'édition d'un éditeur existant
    /// - Parameter editor: L'éditeur à modifier
    func prepareForEdit(editor: Editor) {
        selectedEditor = editor
        editorName = editor.nom
    }
    
    /// Réinitialise le formulaire
    func clearForm() {
        editorName = ""
        selectedEditor = nil
    }
}

