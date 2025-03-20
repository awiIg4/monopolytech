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
        ManageItem(label: "Game Deposit", route: "game/deposit"),
        ManageItem(label: "Game Sale", route: "game/sale"),
        ManageItem(label: "Create Buyer", route: "buyer/create"),
        ManageItem(label: "Create Manager", route: "manager/create"),
        ManageItem(label: "Create Session", route: "session/create"),
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
        // À implémenter
    }
}
