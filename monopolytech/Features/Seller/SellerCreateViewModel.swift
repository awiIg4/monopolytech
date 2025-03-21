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
        isValidEmail(email) && 
        telephone.count >= 10 &&
        !adresse.isEmpty // Adresse est obligatoire
    }
    
    /// Valide le format de l'email
    private func isValidEmail(_ email: String) -> Bool {
        // Vérification simple: non vide, contient @, et au moins un . après @
        let emailParts = email.split(separator: "@")
        if emailParts.count != 2 { return false }
        
        let domain = emailParts[1]
        // Vérifier que le domaine contient au moins un point et au moins 2 caractères après le point
        let domainParts = domain.split(separator: ".")
        if domainParts.count < 2 { return false }
        if let lastPart = domainParts.last, lastPart.count < 2 { return false }
        
        return true
    }
    
    /// Crée un nouveau vendeur
    func createSeller() async {
        if (!isFormValid) {
            if nom.isEmpty {
                errorMessage = "Le nom est requis"
            } else if !isValidEmail(email) {
                errorMessage = "L'email est invalide"
            } else if telephone.count < 10 {
                errorMessage = "Le téléphone doit contenir au moins 10 chiffres"
            } else if adresse.isEmpty {
                errorMessage = "L'adresse est requise"
            } else {
                errorMessage = "Veuillez remplir tous les champs obligatoires correctement"
            }
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
                adresse: adresse // Toujours envoyer l'adresse
            )
            
            let seller = try await sellerService.createSeller(request)
            
            await MainActor.run {
                successMessage = "Vendeur \(seller.nom) créé avec succès"
                showAlert = true
                isLoading = false
                clearForm()
            }
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = parseApiError(error)
                showAlert = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de la création: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
            }
        }
    }
    // TODO: fix too many error messages to be displayed
    /// Analyse une erreur API pour extraire les messages pertinents
    private func parseApiError(_ error: APIError) -> String {
        if case .serverError(let statusCode, let message) = error, statusCode == 400 {
            // Essayer de parser les erreurs JSON spécifiques
            if let errorData = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errors = json["errors"] as? [[String: Any]] {
                
                var errorMessages = [String]()
                
                
                for errorItem in errors {
                    if let path = errorItem["path"] as? String,
                       let msg = errorItem["msg"] as? String {
                        errorMessages.append("\(msg) (\(path))")
                        return msg
                    } else if let msg = errorItem["msg"] as? String {
                        errorMessages.append(msg)
                        return msg
                    }
                }

                
                if !errorMessages.isEmpty {
                    return errorMessages.joined(separator: "\n")
                }
            }
        }
        
        return "Erreur lors de la création: \(error.localizedDescription)"
    }
    
    /// Réinitialise le formulaire
    func clearForm() {
        nom = ""
        email = ""
        telephone = ""
        adresse = ""
    }
}
