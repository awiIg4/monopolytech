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
    
    private let managerService = ManagerService.shared
    
    var isFormValid: Bool {
        !nom.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        telephone.count >= 10 &&
        !adresse.isEmpty &&
        motdepasse.count >= 6
    }
    
    func createManager() async throws {
        let request = ManagerService.CreateManagerRequest(
            nom: nom,
            email: email,
            telephone: telephone,
            adresse: adresse,
            motdepasse: motdepasse
        )
        
        print("Création d'un gestionnaire avec les données: \(nom), \(email)")
        try await managerService.createManager(request)
    }
    
    func clearForm() {
        nom = ""
        email = ""
        telephone = ""
        adresse = ""
        motdepasse = ""
    }
}

