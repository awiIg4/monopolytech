//
//  GameSaleViewModel.swift
//  monopolytech
//
//  Created by eugenio on 29/03/2025.
//

import Foundation
import Combine

class GameSaleViewModel: ObservableObject {
    // Formulaire d'achat
    @Published var gameIds: String = ""
    @Published var buyerEmail: String = ""
    @Published var promoCode: String = ""
    @Published var hasPromoCode: Bool = false
    
    // État
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var showSuccess: Bool = false
    
    // Données
    @Published var buyer: Buyer? = nil
    @Published var purchaseResult: GamePurchaseResult? = nil
    @Published var showInvoice: Bool = false
    
    // Services
    private let gameService = GameService.shared
    private let buyerService = BuyerService.shared
    
    /// Recherche un acheteur par email
    func fetchBuyer() async {
        let email = buyerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if email.isEmpty {
            await MainActor.run {
                self.buyer = nil
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let buyer = try await buyerService.getBuyerByEmail(email: email)
            
            await MainActor.run {
                self.buyer = buyer
                self.isLoading = false
                self.errorMessage = ""
            }
        } catch {
            await MainActor.run {
                self.buyer = nil
                self.isLoading = false
                self.errorMessage = "Acheteur non trouvé: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    /// Effectue l'achat des jeux
    func purchaseGames() async {
        // Validation des IDs de jeux
        let idsString = gameIds.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if idsString.isEmpty {
            errorMessage = "Veuillez entrer au moins un ID de jeu"
            showAlert = true
            return
        }
        
        // Parser les IDs
        let ids = idsString.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if ids.isEmpty {
            errorMessage = "Format d'IDs invalide, utilisez des nombres séparés par des virgules"
            showAlert = true
            return
        }
        
        // Validation du code promo
        let promoString = hasPromoCode ? promoCode.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        if hasPromoCode && (promoString?.isEmpty ?? true) {
            errorMessage = "Veuillez entrer un code promo ou décocher l'option"
            showAlert = true
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let result = try await gameService.buyGames(
                gameIds: ids,
                promoCode: promoString,
                buyerId: buyer?.id != nil ? String(buyer!.id) : nil
            )
            
            await MainActor.run {
                self.purchaseResult = result
                self.showInvoice = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur lors de l'achat: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    /// Génère le contenu d'une facture au format texte
    func generateInvoiceContent() -> String {
        guard let result = purchaseResult else {
            return "Aucune donnée d'achat disponible"
        }
        
        var content = "=== Facture d'Achat ===\n\n"
        
        // Ajouter les informations de l'acheteur si disponibles
        if let buyer = self.buyer {
            content += "🧑 INFORMATIONS ACHETEUR\n"
            content += "Nom: \(buyer.nom)\n"
            content += "Email: \(buyer.email)\n"
            
            // Ajouter le téléphone si présent
            if !buyer.telephone.isEmpty {
                content += "Téléphone: \(buyer.telephone)\n"
            }
            
            // Ajouter l'adresse si présente
            if let adresse = buyer.adresse, !adresse.isEmpty {
                content += "Adresse: \(adresse)\n"
            }
            
            content += "\n------------------------------------------\n\n"
        }
        
        content += "📋 DÉTAIL DES ACHATS\n\n"
        
        for game in result.purchasedGames {
            content += "Jeu : \(game.name)\n"
            content += "Prix : \(String(format: "%.2f", game.price)) €\n"
            content += "Commission : \(String(format: "%.2f", game.commission)) €\n"
            content += "Total après commission : \(String(format: "%.2f", game.total)) €\n"
            
            if let editor = game.editorName {
                content += "Éditeur : \(editor)\n"
            }
            
            if let vendor = game.vendorName {
                content += "Vendeur : \(vendor)\n"
            }
            
            content += "----------------------\n"
        }
        
        content += "\n💰 Total à payer : \(String(format: "%.2f", result.finalAmount)) €\n"
        
        if result.discount > 0 {
            content += "🏷️ Réduction appliquée : \(String(format: "%.2f", result.discount)) €\n"
        }
        
        // Ajouter la date et l'heure de l'achat
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "fr_FR")
        content += "\nDate: \(dateFormatter.string(from: Date()))\n"
        
        return content
    }
    
    /// Réinitialise le formulaire après un achat
    func resetForm() {
        gameIds = ""
        buyerEmail = ""
        promoCode = ""
        hasPromoCode = false
        buyer = nil
        purchaseResult = nil
        showInvoice = false
    }
}
