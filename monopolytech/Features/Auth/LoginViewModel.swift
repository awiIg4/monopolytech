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
    @Published var userType: String = "admin"  // Default to admin
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    
    // User type options (admin and gestionnaire only)
    let userTypeOptions = ["admin", "gestionnaire"]
    
    private let authService = AuthService.shared
    
    /// Attempt to authenticate with current credentials
    func login() async {
        if !validateInputs() {
            return
        }
        
        await MainActor.run { 
            isLoading = true 
            errorMessage = ""
        }
        
        do {
            // Use the correct authentication method based on user type
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
    
    /// Validate form inputs before submission
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
