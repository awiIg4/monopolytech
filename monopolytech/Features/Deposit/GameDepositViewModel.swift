//
//  GameDepositViewModel.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation
import Combine

/// ViewModel pour la fonctionnalité de dépôt de jeu
class GameDepositViewModel: ObservableObject {
    // Formulaire principal
    @Published var sellerEmail: String = ""
    @Published var hasPromoCode: Bool = false
    @Published var promoCode: String = ""
    
    // Formulaire d'ajout de jeu
    @Published var selectedLicense: License?
    @Published var price: String = ""
    @Published var quantity: String = "1"
    
    // Données
    @Published var licenses: [License] = []
    @Published var gamesToDeposit: [GameToDeposit] = []
    
    // État
    @Published var isLoading: Bool = false
    @Published var isLoadingLicenses: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Services
    private let gameService = GameService.shared
    private let licenseService = LicenseService.shared
    private let sellerService = SellerService.shared
    
    init() {
        loadLicenses()
    }
    
    /// Charge la liste des licences disponibles
    func loadLicenses() {
        isLoadingLicenses = true
        
        Task {
            do {
                let fetchedLicenses = try await licenseService.fetchLicenses()
                
                await MainActor.run {
                    self.licenses = fetchedLicenses
                    self.isLoadingLicenses = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de charger les licences: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoadingLicenses = false
                }
            }
        }
    }
    
    /// Ajoute un jeu à la liste à déposer
    func addGame() {
        guard validateGameForm() else {
            return
        }
        
        guard let license = selectedLicense,
              let priceValue = Double(price.replacingOccurrences(of: ",", with: ".")),
              let quantityValue = Int(quantity) else {
            errorMessage = "Données de formulaire invalides"
            showAlert = true
            return
        }
        
        let gameToDeposit = GameToDeposit(
            licenseId: license.id,
            licenseName: license.nom,
            price: priceValue,
            quantity: quantityValue
        )
        
        gamesToDeposit.append(gameToDeposit)
        resetGameForm()
    }
    
    /// Supprime un jeu de la liste
    func removeGame(at index: Int) {
        guard index >= 0 && index < gamesToDeposit.count else {
            errorMessage = "Index invalide"
            showAlert = true
            return
        }
        
        gamesToDeposit.remove(at: index)
    }
    
    /// Soumet le formulaire complet de dépôt
    func submitDeposit() {
        print("📍 SUBMIT DEPOSIT CALLED")
        
        guard validateMainForm() else {
            print("❌ FORM VALIDATION FAILED")
            return
        }
        
        print("✅ FORM VALIDATION PASSED")
        isLoading = true
        
        Task {
            do {
                print("🔍 LOOKING FOR SELLER: \(sellerEmail)")
                // Récupérer le vendeur par email
                let seller = try await sellerService.getSellerByEmail(email: sellerEmail)
                print("✅ SELLER FOUND: \(seller.id)")
                
                // Préparer la requête
                let licenseIds = gamesToDeposit.map { Int($0.licenseId)! }  // Convertir String en Int
                let prices = gamesToDeposit.map { $0.price }
                let quantities = gamesToDeposit.map { $0.quantity }
                let codePromo = hasPromoCode ? promoCode : nil
                
                print("📦 REQUEST DATA PREPARED:")
                print("  - Licenses: \(licenseIds)")
                print("  - Prices: \(prices)")
                print("  - Quantities: \(quantities)")
                
                // Construire la requête
                let request = GameDepositRequest(
                    licence: licenseIds,
                    prix: prices,
                    quantite: quantities,
                    code_promo: codePromo,
                    id_vendeur: seller.id
                )
                
                print("🚀 CALLING depositGames WITH REQUEST")
                // Envoyer la requête
                let depositedGames = try await gameService.depositGames(request: request)
                
                print("✅ DEPOSIT COMPLETED")
                await MainActor.run {
                    self.successMessage = "Dépôt réussi de \(depositedGames.count) jeu(x)!"
                    self.showAlert = true
                    self.isLoading = false
                    self.resetAllForms()
                }
            } catch {
                print("❌ ERROR DURING DEPOSIT: \(error)")
                await MainActor.run {
                    if error.localizedDescription.contains("404") {
                        self.errorMessage = "Le vendeur n'existe pas"
                    } else {
                        self.errorMessage = "Erreur lors du dépôt: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Valide le formulaire d'ajout de jeu
    private func validateGameForm() -> Bool {
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
        } else {
            errorMessage = "Format de quantité invalide"
            showAlert = true
            return false
        }
        
        return true
    }
    
    /// Valide le formulaire principal de dépôt
    private func validateMainForm() -> Bool {
        if sellerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Veuillez entrer l'email du vendeur"
            showAlert = true
            return false
        }
        
        if gamesToDeposit.isEmpty {
            errorMessage = "Veuillez ajouter des jeux avant de valider votre dépôt"
            showAlert = true
            return false
        }
        
        if hasPromoCode && promoCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Veuillez entrer un code promo ou décocher l'option"
            showAlert = true
            return false
        }
        
        return true
    }
    
    /// Réinitialise le formulaire d'ajout de jeu
    private func resetGameForm() {
        selectedLicense = nil
        price = ""
        quantity = "1"
    }
    
    /// Réinitialise tous les formulaires
    private func resetAllForms() {
        resetGameForm()
        sellerEmail = ""
        hasPromoCode = false
        promoCode = ""
        gamesToDeposit = []
    }
}
