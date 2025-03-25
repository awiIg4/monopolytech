//
//  BilanViewModel.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation
import SwiftUI

class BilanViewModel: ObservableObject {
    @Published var bilan: BilanModel?
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    
    // Utiliser GestionService au lieu de SellerService
    private let gestionService = GestionService.shared
    
    init() {
        loadBilan()
    }
    
    func loadBilan() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Utiliser GestionService pour charger le bilan
                let bilanData = try await gestionService.getBilanCurrentSession()
                
                await MainActor.run {
                    self.bilan = bilanData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du chargement du bilan: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Formate une date pour l'affichage
    func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}
