//
//  SellerListView.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import SwiftUI

/// Vue affichant une liste de vendeurs avec possibilité de voir les détails
struct SellerListView: View {
    let sellers: [Seller]
    @State private var selectedSeller: Seller?
    @State private var showingSellerDetails = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sellers) { seller in
                    UserCard(user: seller)
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedSeller = seller
                                showingSellerDetails.toggle()
                            } label: {
                                Label("Info", systemImage: "info.circle")
                            }
                            .tint(.blue)
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Vendeurs")
        }
        .fullScreenCover(item: $selectedSeller) { seller in
            SellerFullDetailView(seller: seller)
        }
    }
}

/// Vue détaillée d'un vendeur
struct SellerFullDetailView: View {
    let seller: Seller
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Informations personnelles")
                    .font(.title2)
                    .bold()
                
                Divider()
                
                Group {
                    DetailRow(icon: "person.fill", title: "Nom", value: seller.displayName)
                    DetailRow(icon: "envelope.fill", title: "Email", value: seller.displayEmail)
                    DetailRow(icon: "phone.fill", title: "Téléphone", value: seller.displayPhone)
                    DetailRow(icon: "location.fill", title: "Adresse", value: seller.displayAddress)
                }
                .padding(.vertical, 4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

/// Ligne affichant une information avec icône, titre et valeur
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct SellerListView_Previews: PreviewProvider {
    static var previews: some View {
        SellerListView(sellers: [
            Seller.placeholder,
            Seller.placeholder,
            Seller.placeholder
        ])
    }
}

