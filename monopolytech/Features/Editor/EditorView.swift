//
//  EditorView.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if viewModel.editors.isEmpty {
                    VStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Aucun éditeur trouvé")
                            .font(.headline)
                        
                        Text("Créez un nouvel éditeur en appuyant sur le bouton +")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.editors, id: \.id) { editor in
                            EditorRow(editor: editor, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            deleteEditor(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadEditors()
                    }
                }
            }
            .navigationTitle("Éditeurs")
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
                EditorFormView(
                    viewModel: viewModel,
                    isEdit: false,
                    onSave: {
                        Task {
                            if await viewModel.createEditor() {
                                viewModel.showCreateSheet = false
                                NotificationService.shared.showSuccess("Éditeur créé avec succès")
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let _ = viewModel.selectedEditor {
                    EditorFormView(
                        viewModel: viewModel,
                        isEdit: true,
                        onSave: {
                            Task {
                                if await viewModel.updateEditor() {
                                    viewModel.showEditSheet = false
                                    NotificationService.shared.showSuccess("Éditeur mis à jour avec succès")
                                }
                            }
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadEditors()
        }
        .toastMessage()
    }
    
    private func deleteEditor(at indexSet: IndexSet) {
        for index in indexSet {
            let editor = viewModel.editors[index]
            
            Task {
                let success = await viewModel.deleteEditor(id: editor.id)
                
                if success {
                    NotificationService.shared.showSuccess("Éditeur supprimé avec succès")
                } else {
                    let errorMessage = viewModel.errorMessage?.replacingOccurrences(of: "Erreur lors de la suppression de l'éditeur: ", with: "") ?? "Erreur lors de la suppression"
                    
                    NotificationService.shared.showInfo(errorMessage)
                }
            }
        }
    }
}

struct EditorRow: View {
    let editor: Editor
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête avec le nom de l'éditeur
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.blue)
                    
                    Text(editor.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Information sur l'ID de l'éditeur
            HStack {
                Text("ID:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(editor.id)
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
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
                    await viewModel.deleteEditor(id: editor.id)
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
            
            Button {
                viewModel.prepareForEdit(editor: editor)
                viewModel.showEditSheet = true
            } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct EditorFormView: View {
    @ObservedObject var viewModel: EditorViewModel
    var isEdit: Bool
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de l'éditeur")) {
                    TextField("Nom de l'éditeur", text: $viewModel.editorName)
                }
                
                Section {
                    Button(action: {
                        // Avant d'appeler onSave, vérifier les validations
                        if viewModel.editorName.isEmpty {
                            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: "Le nom de l'éditeur ne peut pas être vide"
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
                    .disabled(viewModel.editorName.isEmpty)
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
            .navigationTitle(isEdit ? "Modifier l'éditeur" : "Nouvel éditeur")
            .navigationBarItems(trailing: Button("Annuler") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .toastMessage()
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView()
    }
}

