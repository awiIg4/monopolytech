//
//  SellerCreateViewModel.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import Foundation

class SellerCreateViewModel: ObservableObject {
    @Published var nom = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var adresse = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert = false
    
    private let sellerService = SellerService.shared
    
    /// Vérifie si le formulaire est valide
    var isFormValid: Bool {
        !nom.isEmpty && 
        !email.isEmpty && 
        email.contains("@") && 
        telephone.count >= 10
    }
    
    /// Crée un nouveau vendeur
    func createSeller() async {
        if !isFormValid {
            errorMessage = "Veuillez remplir tous les champs obligatoires correctement"
            showAlert = true
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            successMessage = ""
        }
        
        do {
            let request = SellerService.CreateSellerRequest(
                nom: nom,
                email: email,
                telephone: telephone,
                adresse: adresse.isEmpty ? nil : adresse
            )
            
            let seller = try await sellerService.createSeller(request)
            
            await MainActor.run {
                successMessage = "Vendeur \(seller.nom) créé avec succès"
                showAlert = true
                isLoading = false
                clearForm()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
            }
        }
    }
    
    /// Réinitialise le formulaire
    func clearForm() {
        nom = ""
        email = ""
        telephone = ""
        adresse = ""
    }
}
