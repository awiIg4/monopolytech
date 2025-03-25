//
//  PromoCodeViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import Foundation
import SwiftUI

@MainActor
class PromoCodeViewModel: ObservableObject {
    // Données
    @Published var promoCodes: [CodePromo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Formulaire pour la création/modification
    @Published var promoCodeLibelle: String = ""
    @Published var promoCodeReduction: Double = 0
    
    // États pour les sheets et alertes
    @Published var showCreateSheet: Bool = false
    
    private let promoCodeService = PromoCodeService.shared
    
    init() {
        Task {
            await loadPromoCodes()
        }
    }
    
    func loadPromoCodes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Appel direct au service sans transformation complexe
            promoCodes = try await promoCodeService.fetchPromoCodes()
            print("Codes promo chargés avec succès: \(promoCodes.count) codes")
        } catch {
            // Erreur générique
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
            print("Erreur détaillée: \(error)")
            
            // Liste vide, pas de données fictives
            promoCodes = []
            
            // Notification - Correction : utiliser NSError au lieu de String
            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Échec du chargement des codes promo"
            ]))
        }
        
        isLoading = false
    }
    
    // Fonction auxiliaire pour extraire le code de statut d'une erreur API
    private func getStatusCode(from error: APIError) -> Int? {
        // Cette implémentation dépend de la structure de votre APIError
        // Si vous avez un cas .serverError(code, message), vous pouvez l'extraire
        // Sinon, analysez simplement la description pour des codes communs
        
        let description = error.localizedDescription
        
        // Vérifier les codes d'erreur courants
        if description.contains("404") {
            return 404
        } else if description.contains("403") {
            return 403
        } else if description.contains("401") {
            return 401
        } else if description.contains("500") {
            return 500
        }
        
        return nil
    }
    
    /// Crée un nouveau code promo
    func createPromoCode() async {
        if promoCodeLibelle.isEmpty {
            NotificationService.shared.showInfo("Le libellé du code promo ne peut pas être vide")
            return
        }
        
        if promoCodeReduction <= 0 || promoCodeReduction > 100 {
            NotificationService.shared.showInfo("La réduction doit être comprise entre 1 et 100%")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Conversion explicite en Int car l'API attend un Int
            let reductionAsInt = Int(promoCodeReduction)
            
            _ = try await promoCodeService.createPromoCode(
                libelle: promoCodeLibelle,
                reductionPourcent: reductionAsInt
            )
            
            // Message de succès simple et clair
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationService.shared.showSuccess("Code promo '\(self.promoCodeLibelle)' créé avec succès")
            }
            
            // Réinitialiser les champs
            promoCodeLibelle = ""
            promoCodeReduction = 10
            
            // Fermer la feuille de création
            showCreateSheet = false
            
            // Recharger la liste des codes promo
            await loadPromoCodes()
        } catch {
            errorMessage = "Erreur lors de la création du code promo: \(error.localizedDescription)"
            print("Erreur détaillée: \(error)")
            
            // Créer un NSError pour le message d'erreur
            let nsError = NSError(
                domain: "PromoCodeError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de créer le code promo"]
            )
            NotificationService.shared.showError(nsError)
        }
        
        isLoading = false
    }
    
    func deletePromoCode(libelle: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await promoCodeService.deletePromoCode(libelle: libelle)
            await loadPromoCodes()
            isLoading = false
            
            return true
        } catch let error as APIError {
            // Format spécifique pour les erreurs API pour une meilleure lisibilité
            if case .serverError(let code, let message) = error {
                if code == 409 || code == 400 {
                    // Erreurs logiques métier (conflit, validation)
                    errorMessage = "Impossible de supprimer ce code promo : \(message)"
                } else if code == 403 {
                    errorMessage = "Vous n'avez pas les droits pour supprimer ce code promo"
                } else {
                    errorMessage = "Erreur serveur : \(message)"
                }
            } else {
                errorMessage = "Erreur : \(error.localizedDescription)"
            }
        } catch {
            // Erreurs génériques - simplifiées et plus lisibles
            errorMessage = "Impossible de supprimer ce code promo"
        }
        
        // Recharger quand même la liste pour que l'UI reste utilisable
        await loadPromoCodes()
        
        isLoading = false
        return false
    }
    
    func clearForm() {
        promoCodeLibelle = ""
        promoCodeReduction = 0
    }
}

