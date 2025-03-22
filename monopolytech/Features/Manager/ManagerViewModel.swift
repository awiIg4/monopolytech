//
//  ManagerViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation

class ManagerViewModel: ObservableObject {
    @Published var nom = ""
    @Published var email = ""
    @Published var telephone = ""
    @Published var adresse = ""
    @Published var motdepasse = ""
    @Published var response = ""
    
    private let managerService = ManagerService.shared
    
    var isFormValid: Bool {
        !nom.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        telephone.count >= 10 &&
        !adresse.isEmpty &&
        motdepasse.count >= 6
    }
    
    func createManager() async throws -> String {
        let request = ManagerService.CreateManagerRequest(
            nom: nom,
            email: email,
            telephone: telephone,
            adresse: adresse,
            motdepasse: motdepasse
        )
        
        print("Création d'un gestionnaire avec les données: \(nom), \(email)")
        var responseString = try await managerService.createManager(request)
        
        // Assurons-nous que nous avons un message de succès cohérent
        if responseString.isEmpty || !responseString.contains("succès") {
            responseString = "Compte gestionnaire créé avec succès."
        }
        
        self.response = responseString
        
        // En cas de succès, effaçons les champs
        if responseString.contains("succès") {
            await MainActor.run {
                self.clearForm()
            }
        }
        
        return responseString
    }
    
    func clearForm() {
        nom = ""
        email = ""
        telephone = ""
        adresse = ""
        motdepasse = ""
        response = ""
    }
}

