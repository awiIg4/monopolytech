//
//  SellerService.swift
//  monopolytech
//
//  Created by eugenio on 20/03/2025.
//

import Foundation

/// Service pour gérer les vendeurs
class SellerService {
    static let shared = SellerService()
    
    private let apiService = APIService.shared
    private let endpoint = "vendeurs"
    
    private init() {}
    
    /// Récupère un vendeur par son email
    func getSellerByEmail(email: String) async throws -> User {
        return try await apiService.request("\(endpoint)/\(email)")
    }
}
