//
//  GameDepositViewModel.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation
import Combine

/// ViewModel for the game deposit feature
class GameDepositViewModel: ObservableObject {
    // Form fields
    @Published var selectedLicense: License?
    @Published var price: String = ""
    @Published var quantity: String = "1"
    @Published var promoCode: String = ""
    
    // State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Available options
    @Published var licenses: [License] = []
    
    // Services
    private let gameService = GameService.shared
    private let licenseService = LicenseService.shared
    private let authService = AuthService.shared
    
    init() {
        loadLicenses()
    }
    
    /// Load available licenses from the API
                        
    func loadLicenses() {
        isLoading = true
        
        Task {
            do {
                let fetchedLicenses = try await licenseService.fetchLicenses()
                
                await MainActor.run {
                    self.licenses = fetchedLicenses
                    self.isLoading = false
                }
            } catch {
                print("❌ License load error details: \(error)")
                
                await MainActor.run {
                    self.errorMessage = "Impossible de charger les licences: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Submit game deposit form
    func submitDeposit() {
        guard validateForm() else {
            return
        }
        
        isLoading = true
        
        // Parse form values
        guard let license = selectedLicense,
              let priceValue = Double(price.replacingOccurrences(of: ",", with: ".")),
              let quantityValue = Int(quantity),
              let currentUser = authService.currentUser else {
            errorMessage = "Données de formulaire invalides ou utilisateur non connecté"
            showAlert = true
            isLoading = false
            return
        }
        
        // Get seller ID from current user
        let sellerId = currentUser.id
        
        Task {
            do {
                let promoCodeToUse = promoCode.isEmpty ? nil : promoCode
                
                let depositedGames = try await gameService.depositGame(
                    licenseId: license.id,
                    price: priceValue,
                    quantity: quantityValue,
                    sellerId: sellerId,
                    promoCode: promoCodeToUse
                )
                
                await MainActor.run {
                    self.successMessage = "Dépôt réussi de \(depositedGames.count) jeu(x)!"
                    self.showAlert = true
                    self.isLoading = false
                    self.resetForm()
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
                    case .unauthorized:
                        self.errorMessage = "Vous n'êtes pas autorisé à déposer des jeux"
                    case .serverError(let code, let message):
                        self.errorMessage = "Erreur serveur (\(code)): \(message)"
                    default:
                        self.errorMessage = "Erreur lors du dépôt: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du dépôt: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Validate form fields before submission
    private func validateForm() -> Bool {
        if selectedLicense == nil {
            errorMessage = "Veuillez sélectionner une licence"
            showAlert = true
            return false
        }
        
        if price.isEmpty {
            errorMessage = "Veuillez entrer un prix"
            showAlert = true
            return false
        }
        
        if let priceValue = Double(price.replacingOccurrences(of: ",", with: ".")) {
            if priceValue <= 0 {
                errorMessage = "Le prix doit être supérieur à 0"
                showAlert = true
                return false
            }
        } else {
            errorMessage = "Format de prix invalide"
            showAlert = true
            return false
        }
        
        if let quantityValue = Int(quantity) {
            if quantityValue <= 0 {
                errorMessage = "La quantité doit être supérieure à 0"
                showAlert = true
                return false
            }
            if quantityValue > 10 {
                errorMessage = "La quantité ne peut pas dépasser 10"
                showAlert = true
                return false
            }
        } else {
            errorMessage = "Format de quantité invalide"
            showAlert = true
            return false
        }
        
        if authService.currentUser == nil {
            errorMessage = "Vous devez être connecté pour déposer un jeu"
            showAlert = true
            return false
        }
        
        return true
    }
    
    /// Reset form after successful submission
    private func resetForm() {
        selectedLicense = nil
        price = ""
        quantity = "1"
        promoCode = ""
    }
}
