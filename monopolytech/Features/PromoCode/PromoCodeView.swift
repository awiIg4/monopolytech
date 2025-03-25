//
//  PromoCodeView.swift
//  monopolytech
//
//  Created by Hugo Brun on 24/03/2025.
//

import SwiftUI

struct PromoCodeView: View {
    @StateObject private var viewModel = PromoCodeViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if viewModel.promoCodes.isEmpty {
                    VStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Aucun code promo trouvé")
                            .font(.headline)
                        
                        Text("Créez un nouveau code promo en appuyant sur le bouton +")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.promoCodes, id: \.id) { promoCode in
                            PromoCodeRow(promoCode: promoCode, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            deletePromoCode(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadPromoCodes()
                    }
                }
            }
            .navigationTitle("Codes Promo")
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
                PromoCodeFormView(
                    viewModel: viewModel,
                    isEdit: false,
                    onSave: {
                        Task {
                            await viewModel.createPromoCode()
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadPromoCodes()
        }
        .toastMessage()
    }
    
    private func deletePromoCode(at indexSet: IndexSet) {
        for index in indexSet {
            let promoCode = viewModel.promoCodes[index]
            
            Task {
                let success = await viewModel.deletePromoCode(libelle: promoCode.libelle)
                
                if success {
                    NotificationService.shared.showSuccess("Le code '\(promoCode.libelle)' a été supprimé")
                } else {
                    let errorMessage = "Impossible de supprimer ce code promo"
                    NotificationService.shared.showInfo(errorMessage)
                }
            }
        }
    }
}

struct PromoCodeRow: View {
    let promoCode: CodePromo
    @ObservedObject var viewModel: PromoCodeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête avec le libellé du code
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                    
                    Text(promoCode.displayLibelle)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Information sur la réduction
            HStack {
                Text("Réduction:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(promoCode.displayReduction)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
                
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
                    await viewModel.deletePromoCode(libelle: promoCode.libelle)
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
}

struct PromoCodeFormView: View {
    @ObservedObject var viewModel: PromoCodeViewModel
    var isEdit: Bool
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations du code promo")) {
                    TextField("Libellé", text: $viewModel.promoCodeLibelle)
                    
                    VStack(alignment: .leading) {
                        Text("Réduction (%): \(Int(viewModel.promoCodeReduction))")
                            .font(.subheadline)
                        
                        Slider(value: $viewModel.promoCodeReduction, in: 0...100, step: 1) {
                            Text("Réduction")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Avant d'appeler onSave, vérifier les validations
                        if viewModel.promoCodeLibelle.isEmpty {
                            NotificationService.shared.showError(NSError(domain: "", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: "Le libellé du code promo ne peut pas être vide"
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
                    .disabled(viewModel.promoCodeLibelle.isEmpty)
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
            .navigationTitle(isEdit ? "Modifier le code promo" : "Nouveau code promo")
            .navigationBarItems(trailing: Button("Annuler") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .toastMessage()
    }
}

struct PromoCodeView_Previews: PreviewProvider {
    static var previews: some View {
        PromoCodeView()
    }
}

