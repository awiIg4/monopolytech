//
//  SessionView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

/// Vue principale pour la gestion des sessions de vente
struct SessionView: View {
    @StateObject private var viewModel = SessionViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if viewModel.sessions.isEmpty {
                    VStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Aucune session trouvée")
                            .font(.headline)
                        
                        Text("Créez une nouvelle session en appuyant sur le bouton +")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            SessionRow(session: session, viewModel: viewModel)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        }
                        .onDelete { indexSet in
                            deleteSession(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadSessions()
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.clearForm()
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                SessionFormView(
                    viewModel: viewModel,
                    isEdit: false,
                    onSave: {
                        Task {
                            if await viewModel.createSession() {
                                viewModel.showCreateSheet = false
                                NotificationService.shared.showSuccess("Session créée avec succès")
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let _ = viewModel.selectedSession {
                    SessionFormView(
                        viewModel: viewModel,
                        isEdit: true,
                        onSave: {
                            Task {
                                if await viewModel.updateSession() {
                                    viewModel.showEditSheet = false
                                    NotificationService.shared.showSuccess("Session mise à jour avec succès")
                                }
                            }
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadSessions()
        }
        .toastMessage()
    }
    
    /// Supprime une session à l'index spécifié
    /// - Parameter indexSet: L'index de la session à supprimer
    private func deleteSession(at indexSet: IndexSet) {
        for index in indexSet {
            let session = viewModel.sessions[index]
            
            Task {
                let success = await viewModel.deleteSession(id: session.id)
                
                if success {
                    NotificationService.shared.showSuccess("Session supprimée avec succès")
                }
            }
        }
    }
}

/// Composant d'affichage pour une ligne de session dans la liste
struct SessionRow: View {
    let session: SessionService.Session
    @ObservedObject var viewModel: SessionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête de la session avec un fond coloré
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text("Du \(formatDate(session.date_debut))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.leading, 2)
                    
                    Text("Au \(formatDate(session.date_fin))")
                        .font(.subheadline)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Informations sur la commission et les frais
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Commission")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.valeur_commission)\(session.commission_en_pourcentage ? "%" : "€")")
                        .font(.system(size: 15, weight: .semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Frais de dépôt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.valeur_frais_depot)\(session.frais_depot_en_pourcentage ? "%" : "€")")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            // Date de création et mise à jour si disponibles
            if let createdAt = session.createdAt {
                Text("Créée le \(formatDateWithTime(createdAt))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteSession(id: session.id)
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
            
            Button {
                viewModel.prepareForEdit(session: session)
                viewModel.showEditSheet = true
            } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
    
    /// Formate une date ISO 8601 pour l'affichage (date seule)
    /// - Parameter dateString: La chaîne de date à formater
    /// - Returns: La date formatée
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "dd MMMM yyyy" // Format complet: 01 janvier 2025
            return formatter.string(from: date)
        }
        
        // Parsing manuel en dernier recours
        if dateString.contains("T") {
            let parts = dateString.split(separator: "T")
            if parts.count > 0 {
                let datePart = String(parts[0])
                let dateComponents = datePart.split(separator: "-")
                if dateComponents.count == 3 {
                    return "\(dateComponents[2])/\(dateComponents[1])/\(dateComponents[0])"
                }
                return datePart
            }
        }
        
        return dateString
    }
    
    /// Formate une date ISO 8601 pour l'affichage (date et heure)
    /// - Parameter dateString: La chaîne de date à formater
    /// - Returns: La date et l'heure formatées
    private func formatDateWithTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "dd/MM/yyyy à HH:mm" // Format avec heure
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

/// Vue de formulaire pour la création ou modification d'une session
struct SessionFormView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    let isEdit: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dates")) {
                    DatePicker("Date de début", selection: $viewModel.dateDebut, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Date de fin", selection: $viewModel.dateFin, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Commission")) {
                    Stepper("Valeur: \(viewModel.valeurCommission)", value: $viewModel.valeurCommission, in: 0...100)
                    Toggle("En pourcentage", isOn: $viewModel.commissionEnPourcentage)
                }
                
                Section(header: Text("Frais de dépôt")) {
                    Stepper("Valeur: \(viewModel.valeurFraisDepot)", value: $viewModel.valeurFraisDepot, in: 0...100)
                    Toggle("En pourcentage", isOn: $viewModel.fraisDepotEnPourcentage)
                }
            }
            .navigationTitle(isEdit ? "Modifier la session" : "Nouvelle session")
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                },
                trailing: Button("Enregistrer") {
                    onSave()
                }
            )
        }
    }
}

