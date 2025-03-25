//
//  ManageItem.swift
//  monopolytech
//
//  Created by Hugo Brun on 22/03/2025.
//

import Foundation

/// Structure représentant un élément du menu de gestion
struct ManageItem: Identifiable {
    let id = UUID()
    let label: String
    let route: String
    let icon: String
}

