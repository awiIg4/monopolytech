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
        ManageItem(label: "Manage Seller", route: "seller"),
        ManageItem(label: "Déposer un jeu", route: "game/deposit"),
        ManageItem(label: "Game Sale", route: "game/sale"),
        ManageItem(label: "Statistiques", route: "seller/stats"),
        ManageItem(label: "Create Buyer", route: "buyer/create"),
        ManageItem(label: "Créer un gestionnaire", route: "manager/create"),
        ManageItem(label: "Créer une session", route: "session/create"),
        ManageItem(label: "Create License", route: "license/create"),
        ManageItem(label: "Create Editor", route: "editor/create"),
        ManageItem(label: "Put games for sale", route: "game/stockToSale"),
        ManageItem(label: "Create Sales Code", route: "code-promo"),
        ManageItem(label: "Show Current Session Stats", route: "bilan")
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
