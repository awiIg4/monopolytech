//
//  BuyerViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 25/03/2025.
//

import Foundation
import Combine

/// ViewModel pour la gestion des acheteurs
class BuyerViewModel: ObservableObject {
    // Services
    private let buyerService = BuyerService.shared
    
    // États de l'UI
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Données de formulaire
    @Published var nom = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var adresse = ""
    
    // État des sheets
    @Published var showRegisterSheet = false
    
    // Validation
    @Published var isFormValid = false
    
    // Données chargées
    @Published var buyer: Buyer? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
    }
    
    /// Configure la validation du formulaire
    private func setupValidation() {
        Publishers.CombineLatest4($nom, $email, $telephone, $adresse)
            .map { nom, email, telephone, adresse in
                !nom.isEmpty && 
                self.isValidEmail(email) && 
                telephone.count >= 10 && 
                !adresse.isEmpty
            }
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
    }
    
    /// Vérifie si un email est valide
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Charge les informations d'un acheteur par son email
    func loadBuyerByEmail() async {
        if email.isEmpty {
            NotificationService.shared.showInfo("Veuillez entrer un email")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            buyer = try await buyerService.getBuyerByEmail(email: email)
        } catch let error as APIError {
            let errorDescription: String
            
            switch error {
            case .serverError(let code, let message):
                errorDescription = "Erreur \(code): \(message)"
                if code == 404 {
                    NotificationService.shared.showInfo("Aucun acheteur trouvé avec cet email")
                } else {
                    NotificationService.shared.showError(NSError(domain: "", code: code, userInfo: [
                        NSLocalizedDescriptionKey: message
                    ]))
                }
            default:
                errorDescription = error.localizedDescription
                NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Impossible de charger l'acheteur"
                ]))
            }
            
            errorMessage = errorDescription
            buyer = nil
        } catch {
            errorMessage = "Erreur inattendue: \(error.localizedDescription)"
            
            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Impossible de charger l'acheteur"
            ]))
            
            buyer = nil
        }
        
        isLoading = false
    }
    
    /// Enregistre un nouvel acheteur
    func registerBuyer() async {
        if !isFormValid {
            NotificationService.shared.showInfo("Veuillez remplir correctement tous les champs")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let message = try await buyerService.registerBuyer(
                nom: nom,
                email: email,
                telephone: telephone,
                adresse: adresse
            )
            
            // Afficher un message de succès après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationService.shared.showSuccess("Compte acheteur créé avec succès")
            }
            
            // Réinitialiser les champs
            resetForm()
            
            // Fermer la feuille d'enregistrement
            showRegisterSheet = false
        } catch let error as APIError {
            let errorDescription: String
            
            switch error {
            case .serverError(let code, let message):
                errorDescription = "Erreur \(code): \(message)"
                if message.contains("existe déjà") {
                    NotificationService.shared.showInfo("Un utilisateur avec cet email existe déjà")
                } else {
                    NotificationService.shared.showError(NSError(domain: "", code: code, userInfo: [
                        NSLocalizedDescriptionKey: message
                    ]))
                }
            default:
                errorDescription = error.localizedDescription
                NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Impossible de créer le compte acheteur"
                ]))
            }
            
            errorMessage = errorDescription
        } catch {
            errorMessage = "Erreur inattendue: \(error.localizedDescription)"
            
            // Créer un NSError pour le message d'erreur
            NotificationService.shared.showError(NSError(domain: "BuyerError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Impossible de créer le compte acheteur"
            ]))
        }
        
        isLoading = false
    }
    
    /// Réinitialise le formulaire d'enregistrement
    func resetForm() {
        nom = ""
        email = ""
        telephone = ""
        adresse = ""
    }
}

