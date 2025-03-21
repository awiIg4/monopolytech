//
//  SellerMainView.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import SwiftUI

struct SellerMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
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
        }
        .navigationTitle("Vendeurs")
    }
}

struct SellerMainView_Previews: PreviewProvider {
    static var previews: some View {
        SellerMainView()
    }
}
