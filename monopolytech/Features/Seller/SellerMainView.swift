//
//  SellerMainView.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import SwiftUI

/// Vue principale pour la gestion des vendeurs, avec onglets pour créer et gérer
struct SellerMainView: View {
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Segment control pour basculer entre les vues
                Picker("", selection: $selectedTab) {
                    Text("Créer").tag(0)
                    Text("Gérer").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                // Contenu basé sur l'onglet sélectionné
                if selectedTab == 0 {
                    SellerCreateView()
                } else {
                    SellerManageView()
                }
                
                Spacer()
            }
            .navigationBarTitle("Gestion des Vendeurs", displayMode: .inline)
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
        }
        // Suppression du NavigationView imbriqué si présenté dans une sheet
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SellerMainView_Previews: PreviewProvider {
    static var previews: some View {
        SellerMainView()
    }
}
