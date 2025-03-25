//
//  LoginViewModel.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation
import Combine

/// ViewModel pour gérer la logique d'authentification
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var userType: String = "admin"  // Par défaut admin
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    
    // Options de type d'utilisateur (admin et gestionnaire uniquement)
    let userTypeOptions = ["admin", "gestionnaire"]
    
    private let authService = AuthService.shared
    
    /// Tente de s'authentifier avec les identifiants actuels
    func login() async {
        if !validateInputs() {
            return
        }
        
        await MainActor.run { 
            isLoading = true 
            errorMessage = ""
        }
        
        do {
            // Utilise la méthode d'authentification appropriée selon le type d'utilisateur
            let user = try await authService.login(email: email, password: password, userType: userType)
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
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
    
    /// Valide les champs du formulaire avant soumission
    private func validateInputs() -> Bool {
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
