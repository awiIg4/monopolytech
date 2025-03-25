//
//  LicenseView.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import SwiftUI

/// Vue principale pour la gestion des licences de jeux
struct LicenseView: View {
    @StateObject private var viewModel = LicenseViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if viewModel.licenses.isEmpty {
                    VStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Aucune licence trouvée")
                            .font(.headline)
                        
                        Text("Créez une nouvelle licence en appuyant sur le bouton +")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.licenses, id: \.id) { license in
                            LicenseRow(license: license, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            deleteLicense(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadLicenses()
                    }
                }
            }
            .navigationTitle("Licences")
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                },
                trailing: Button {
                    viewModel.clearForm()
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $viewModel.showCreateSheet) {
                LicenseFormView(
                    viewModel: viewModel,
                    isEdit: false,
                    onSave: {
                        Task {
                            if await viewModel.createLicense() {
                                viewModel.showCreateSheet = false
                                NotificationService.shared.showSuccess("Licence créée avec succès")
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let _ = viewModel.selectedLicense {
                    LicenseFormView(
                        viewModel: viewModel,
                        isEdit: true,
                        onSave: {
                            Task {
                                if await viewModel.updateLicense() {
                                    viewModel.showEditSheet = false
                                    NotificationService.shared.showSuccess("Licence mise à jour avec succès")
                                }
                            }
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadLicenses()
        }
        .toastMessage()
    }
    
    /// Supprime une licence à l'index spécifié
    /// - Parameter indexSet: L'index de la licence à supprimer
    private func deleteLicense(at indexSet: IndexSet) {
        for index in indexSet {
            let license = viewModel.licenses[index]
            
            Task {
                let success = await viewModel.deleteLicense(id: license.id)
                
                if success {
                    NotificationService.shared.showSuccess("Licence supprimée avec succès")
                } else {
                    let errorMessage = viewModel.errorMessage?.replacingOccurrences(of: "Erreur lors de la suppression de la licence: ", with: "") ?? "Erreur lors de la suppression"
                    
                    NotificationService.shared.showInfo(errorMessage)
                }
            }
        }
    }
}

/// Composant d'affichage pour une ligne de licence dans la liste
struct LicenseRow: View {
    let license: License
    @ObservedObject var viewModel: LicenseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête avec le nom de la licence
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    
                    Text(license.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Information sur l'éditeur
            HStack {
                Text("Éditeur ID:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(license.displayEditeurId)
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                // Trouve l'éditeur correspondant s'il existe
                if let editorId = license.editeur_id,
                   let editor = viewModel.editors.first(where: { $0.id == editorId }) {
                    Text(editor.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
                    await viewModel.deleteLicense(id: license.id)
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
            
            Button {
                viewModel.prepareForEdit(license: license)
                viewModel.showEditSheet = true
            } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

/// Vue de formulaire pour la création ou modification d'une licence
struct LicenseFormView: View {
    @ObservedObject var viewModel: LicenseViewModel
    var isEdit: Bool
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de la licence")) {
                    TextField("Nom de la licence", text: $viewModel.licenseName)
                    
                    // Sélecteur d'éditeur pour une meilleure expérience utilisateur
                    Picker("Éditeur", selection: $viewModel.editorId) {
                        Text("Sélectionnez un éditeur").tag("")
                        
                        ForEach(viewModel.editors, id: \.id) { editor in
                            Text(editor.displayName).tag(editor.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button(action: {
                        // Avant d'appeler onSave, vérifier les validations
                        if viewModel.licenseName.isEmpty {
                            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: "Le nom de la licence ne peut pas être vide"
                            ]))
                            return
                        }
                        
                        if viewModel.editorId.isEmpty {
                            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: "Veuillez sélectionner un éditeur"
                            ]))
                            return
                        }
                        
                        // Si tout est valide, continuer
                        onSave()
                    }) {
                        Text(isEdit ? "Mettre à jour" : "Créer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.licenseName.isEmpty || viewModel.editorId.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .padding()
                    
                    if isEdit {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Annuler")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                        .listRowInsets(EdgeInsets())
                        .padding()
                    }
                }
            }
            .navigationTitle(isEdit ? "Modifier la licence" : "Nouvelle licence")
            .navigationBarItems(trailing: Button("Annuler") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .toastMessage()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
}

