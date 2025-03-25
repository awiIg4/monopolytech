//
//  ManageViewModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour la gestion du menu principal de l'application
@MainActor
class ManageViewModel: ObservableObject {
    @Published var manageItems: [ManageItem] = [
        ManageItem(label: "Créer un vendeur", route: "seller", icon: "person.badge.plus"),
        ManageItem(label: "Déposer un jeu", route: "game/deposit", icon: "gamecontroller.fill"),
        ManageItem(label: "Vendre des jeux", route: "game/sale", icon: "cart.fill"),
        ManageItem(label: "Statistiques vendeur", route: "seller/stats", icon: "chart.xyaxis.line"),
        ManageItem(label: "Créer un acheteur", route: "buyer/create", icon: "person.crop.circle.badge.plus"),
        ManageItem(label: "Créer un gestionnaire", route: "manager/create", icon: "person.2.circle.fill"),
        ManageItem(label: "Gérer les sessions", route: "session/create", icon: "calendar.badge.plus"),
        ManageItem(label: "Mettre en rayon", route: "game/stockToSale", icon: "arrow.right.doc.on.clipboard"),
        ManageItem(label: "Codes promo", route: "code-promo", icon: "tag.circle.fill"),
        ManageItem(label: "Bilan financier", route: "bilan", icon: "chart.bar.fill"),
        ManageItem(label: "Gérer les licences", route: "license/manage", icon: "doc.badge.plus"),
        ManageItem(label: "Gérer les éditeurs", route: "editor/manage", icon: "building.2.fill")
    ]
    
    @Published var userGames: [Game] = []
    @Published var showAddGameSheet = false
    
    init() {
        // Les éléments du menu sont déjà configurés
    }
}
