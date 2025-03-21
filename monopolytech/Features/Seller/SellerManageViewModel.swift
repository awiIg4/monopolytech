//
//  SellerManageViewModel.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import Foundation

class SellerManageViewModel: ObservableObject {
    @Published var searchEmail = ""
    @Published var currentSeller: User?
    @Published var sellerStats: SellerStats?
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showAlert = false
    
    private let sellerService = SellerService.shared
    
    /// Recherche un vendeur par son email
    func searchSeller() async {
        let email = searchEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if email.isEmpty {
            errorMessage = "Veuillez entrer un email valide"
            showAlert = true
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            // Récupérer le vendeur
            let seller = try await sellerService.getSellerByEmail(email: email)
            
            // Si trouvé, récupérer aussi ses statistiques
            // CORRECTION ICI: seller.id est déjà optionnel, donc on vérifie simplement s'il existe 
            // et n'est pas vide avant de l'utiliser
            let sellerId = seller.id
            if !sellerId.isEmpty {
                do {
                    let stats = try await sellerService.getSellerStats(sellerId: sellerId)
                    
                    await MainActor.run {
                        self.currentSeller = seller
                        self.sellerStats = stats
                        self.isLoading = false
                    }
                } catch {
                    // Si erreur sur les stats, on affiche quand même le vendeur
                    await MainActor.run {
                        self.currentSeller = seller
                        self.sellerStats = nil
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.currentSeller = seller
                    self.sellerStats = nil
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.currentSeller = nil
                self.sellerStats = nil
                self.errorMessage = "Vendeur non trouvé: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    /// Réinitialise les données de recherche
    func clearSearch() {
        searchEmail = ""
        currentSeller = nil
        sellerStats = nil
    }
}
