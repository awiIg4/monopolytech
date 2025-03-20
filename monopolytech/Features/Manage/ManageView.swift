//
//  ManageView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

struct ManageView: View {
    @StateObject private var viewModel = ManageViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Gestion")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Grille de boutons
                LazyVGrid(
                    columns: [GridItem(.flexible())],
                    spacing: 15
                ) {
                    ForEach(viewModel.manageItems) { item in
                        ManageButton(item: item)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }
}

struct ManageButton: View {
    let item: ManageItem
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                Image(systemName: iconForRoute(item.route))
                    .font(.title2)
                
                Text(item.label)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    func iconForRoute(_ route: String) -> String {
        switch route {
        case "seller": return "person.2.fill"
        case "game/deposit": return "plus.app.fill"
        case "game/sale": return "cart.fill"
        case "buyer/create": return "person.badge.plus"
        case "manager/create": return "person.fill.checkmark"
        case "session/create": return "calendar.badge.plus"
        case "license/create": return "doc.badge.plus"
        case "editor/create": return "pencil.and.outline"
        case "game/stockToSale": return "tag.fill"
        case "code-promo": return "ticket.fill"
        case "bilan": return "chart.bar.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    @ViewBuilder
    var destinationView: some View {
        switch item.route {
        case "seller":
            Text("Manage Seller View")
        case "game/deposit":
            Text("Game Deposit View")
        case "game/sale":
            Text("Game Sale View")
        default:
            Text("View not implemented yet")
        }
    }
}

struct ManageItem: Identifiable {
    let id = UUID()
    let label: String
    let route: String
}
