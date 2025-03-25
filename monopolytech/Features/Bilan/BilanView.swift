//
//  BilanView.swift
//  monopolytech
//
//  Created by eugenio on 30/03/2025.
//

import SwiftUI

struct BilanView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = BilanViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Contenu principal
                ScrollView {
                    VStack(spacing: 20) {
                        // Titre
                        Text("Bilan Financier")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        if let bilan = viewModel.bilan {
                            // Informations de session
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Session Actuelle")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                
                                HStack {
                                    Text("Début:")
                                        .fontWeight(.semibold)
                                    Text(viewModel.formatDate(bilan.session.date_debut))
                                }
                                
                                HStack {
                                    Text("Fin:")
                                        .fontWeight(.semibold)
                                    Text(viewModel.formatDate(bilan.session.date_fin))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Données du bilan
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Bilan Financier")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                StatRow(
                                    title: "Total généré",
                                    value: String(format: "%.2f €", bilan.bilan.total_generé_par_vendeurs),
                                    icon: "dollarsign.circle.fill"
                                )
                                
                                StatRow(
                                    title: "Total dû aux vendeurs",
                                    value: String(format: "%.2f €", bilan.bilan.total_dû_aux_vendeurs),
                                    icon: "person.2.fill"
                                )
                                
                                StatRow(
                                    title: "Revenu de l'organisation",
                                    value: String(format: "%.2f €", bilan.bilan.argent_généré_pour_admin),
                                    icon: "building.2.fill"
                                )
                                
                                // Bouton de rafraîchissement
                                Button(action: {
                                    viewModel.loadBilan()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Rafraîchir les données")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding(.top, 20)
                                .disabled(viewModel.isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                        } else if !viewModel.errorMessage.isEmpty {
                            // Message d'erreur
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                    .padding()
                                
                                Text("Erreur lors de la récupération du bilan")
                                    .font(.headline)
                                
                                Text(viewModel.errorMessage)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.red)
                                    .padding()
                                
                                Button(action: {
                                    viewModel.loadBilan()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Réessayer")
                                    }
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding()
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Overlay de chargement
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Chargement du bilan...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                            .font(.headline)
                    }
                    .padding(25)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
            }
            .navigationBarTitle("Bilan Financier", displayMode: .inline)
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
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct BilanView_Previews: PreviewProvider {
    static var previews: some View {
        BilanView()
    }
}
