//
//  ManageView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

struct ManageView: View {
    @StateObject private var viewModel = ManageViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var selectedItem: ManageItem? = nil
    @State private var showDepositView = false
    @State private var showSellerView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.manageItems) { item in
                    Button(action: {
                        selectedItem = item
                        handleAction(for: item)
                    }) {
                        HStack {
                            Image(systemName: getIconName(for: item))
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text(item.label)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Management")
            .sheet(isPresented: $showDepositView) {
                GameDepositView()
            }
            .sheet(isPresented: $showSellerView) {
                SellerMainView()
            }
        }
    }
    
    private func handleAction(for item: ManageItem) {
        switch item.route {
        case "game/deposit":
            showDepositView = true
        case "seller":
            showSellerView = true
        default:
            // Handle other routes
            break
        }
    }
    
    private func getIconName(for item: ManageItem) -> String {
        switch item.route {
        case "seller": return "person.fill"
        case "game/deposit": return "gamecontroller.fill"
        case "game/sale": return "cart.fill"
        case "buyer/create": return "person.badge.plus"
        case "manager/create": return "person.2.fill"
        case "session/create": return "calendar.badge.plus"
        case "license/create": return "doc.badge.plus"
        case "editor/create": return "building.2.fill"
        case "game/stockToSale": return "arrow.right.square.fill"
        case "code-promo": return "tag.fill"
        case "bilan": return "chart.bar.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// Maintenir cette définition ici uniquement
struct ManageItem: Identifiable {
    let id = UUID()
    let label: String
    let route: String
}
