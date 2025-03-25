//
//  BuyerView.swift
//  monopolytech
//
//  Created by Hugo Brun on 25/03/2025.
//

import SwiftUI

struct BuyerView: View {
    @StateObject private var viewModel = BuyerViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Champ de recherche par email
                searchSection
                
                Divider()
                
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if let buyer = viewModel.buyer {
                    buyerDetailsSection(buyer)
                } else {
                    noDataView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Gestion Acheteurs")
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
                    viewModel.resetForm()
                    viewModel.showRegisterSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            )
            .sheet(isPresented: $viewModel.showRegisterSheet) {
                BuyerRegisterView(viewModel: viewModel)
            }
        }
        .toastMessage()
    }
    
    // Vue de recherche par email
    private var searchSection: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.secondary)
            
            TextField("Rechercher par email", text: $viewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            
            Button(action: {
                Task {
                    await viewModel.loadBuyerByEmail()
                }
            }) {
                Text("Rechercher")
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.email.isEmpty)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .padding(.bottom)
    }
    
    // Vue de détails d'un acheteur
    private func buyerDetailsSection(_ buyer: Buyer) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Informations de l'acheteur")
                .font(.headline)
                .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 12) {
                BuyerDetailRow(icon: "person.fill", title: "Nom", value: buyer.displayName)
                BuyerDetailRow(icon: "envelope.fill", title: "Email", value: buyer.displayEmail)
                BuyerDetailRow(icon: "phone.fill", title: "Téléphone", value: buyer.displayPhone)
                BuyerDetailRow(icon: "location.fill", title: "Adresse", value: buyer.displayAddress)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Vue lorsqu'aucun acheteur n'est chargé
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucun acheteur sélectionné")
                .font(.headline)
            
            Text("Recherchez un acheteur par email ou créez-en un nouveau")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Vue pour l'enregistrement d'un nouvel acheteur
struct BuyerRegisterView: View {
    @ObservedObject var viewModel: BuyerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations personnelles")) {
                    TextField("Nom", text: $viewModel.nom)
                        .autocapitalization(.words)
                        .textContentType(.name)
                    
                    TextField("Email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    TextField("Téléphone", text: $viewModel.telephone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    TextField("Adresse", text: $viewModel.adresse)
                        .textContentType(.fullStreetAddress)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.registerBuyer()
                        }
                    }) {
                        Text("Enregistrer")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(viewModel.isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Nouvel acheteur")
            .navigationBarItems(
                leading: Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        Color.black.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView("Enregistrement...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
            )
        }
    }
}

// Composant réutilisable pour afficher une ligne de détails
struct BuyerDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct BuyerView_Previews: PreviewProvider {
    static var previews: some View {
        BuyerView()
    }
}

