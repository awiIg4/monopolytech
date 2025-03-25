//
//  BilanViewModel.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour gérer les données du bilan financier
class BilanViewModel: ObservableObject {
    @Published var bilan: BilanModel?
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    
    private let gestionService = GestionService.shared
    
    init() {
        loadBilan()
    }
    
    /// Charge les données du bilan depuis l'API
    func loadBilan() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
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
        // Méthode avec ISO8601DateFormatter
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        
        // Alternative avec DateFormatter
        let backupFormatter = DateFormatter()
        backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = backupFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "fr_FR")
            outputFormatter.dateFormat = "dd/MM/yyyy"
            return outputFormatter.string(from: date)
        }
        
        // Méthode de secours avec parsing manuel
        if dateString.contains("T") {
            let components = dateString.split(separator: "T")[0].split(separator: "-")
            if components.count == 3 {
                return "\(components[2])/\(components[1])/\(components[0])"
            }
        }
        
        return dateString
    }
    
    /// Formate un montant financier pour l'affichage
    func formatMontant(_ montant: String, suffixe: String = "", préfixe: String = "") -> String {
        // Convertir la chaîne en Double
        guard let valeur = Double(montant.replacingOccurrences(of: ",", with: ".")) else {
            return "\(préfixe)\(montant) \(suffixe)"
        }
        
        // Formater le nombre avec séparateurs de milliers
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        if let texteFormatté = formatter.string(from: NSNumber(value: valeur)) {
            return "\(préfixe)\(texteFormatté) \(suffixe)"
        }
        
        return "\(préfixe)\(montant) \(suffixe)"
    }
}
