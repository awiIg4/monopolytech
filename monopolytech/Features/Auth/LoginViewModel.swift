//
//  LoginViewModel.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var userType: String = "admin"  // Par défaut admin
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    
    private let authService = AuthService.shared
    
    // Options pour les types d'utilisateur (seulement ceux qui existent)
    let userTypeOptions = ["admin", "gestionnaire"]
    
    func login() async {
        if !validateInputs() {
            return
        }
        
        await MainActor.run { 
            isLoading = true 
            errorMessage = ""
        }
        
        do {
            // Utilisation du bon endpoint selon le type d'utilisateur
            let user = try await authService.login(email: email, password: password, userType: userType)
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
                
                // Log pour le debugging
                print("Connecté en tant que: \(user.email)")
                print("Type: \(userType)")
                print("Rôle: \(user.role)")
            }
        } catch let error as AuthError {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Une erreur s'est produite. Veuillez réessayer."
            }
        }
    }
    
    private func validateInputs() -> Bool {
        // Validation des champs
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Veuillez entrer votre email"
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Veuillez entrer votre mot de passe"
            return false
        }
        
        return true
    }
}
