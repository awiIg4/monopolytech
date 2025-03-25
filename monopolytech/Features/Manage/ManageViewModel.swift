//
//  ManageViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation
import SwiftUI

@MainActor
class ManageViewModel: ObservableObject {
    @Published var manageItems: [ManageItem] = [
        ManageItem(label: "Créer un vendeur", route: "seller"),
        ManageItem(label: "Déposer un jeu", route: "game/deposit"),
        ManageItem(label: "Acheter des jeux", route: "game/sale"),
        ManageItem(label: "Create Buyer", route: "buyer/create"),
        ManageItem(label: "Créer un gestionnaire", route: "manager/create"),
        ManageItem(label: "Créer une session", route: "session/create"),
        ManageItem(label: "Mettre des jeux en rayon", route: "game/stockToSale"),
        ManageItem(label: "Gérer les codes promo", route: "code-promo"),
        ManageItem(label: "Show Current Session Stats", route: "bilan"),
        ManageItem(label: "Gérer les licences", route: "license/manage"),
        ManageItem(label: "Gérer les éditeurs", route: "editor/manage")
    ]
    
    @Published var userGames: [Game] = []
    @Published var showAddGameSheet = false
    
    init() {
        setupActions()
    }
    
    private func setupActions() {
        // Handle navigation to GameDepositView when needed
        // This could be through a NavigationLink or sheet presentation
    }
}
