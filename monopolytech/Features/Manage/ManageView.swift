//
//  ManageView.swift
//  monopolytech
//
//  Created by Hugo Brun on 20/03/2025.
//

import SwiftUI

struct ManageView: View {
    @ObservedObject private var viewModel: ManageViewModel
    @EnvironmentObject var authService: AuthService
    @State private var selectedItem: ManageItem? = nil
    @State private var showDepositView = false
    @State private var showSellerView = false
    @State private var showManagerCreationView = false
    @State private var showSessionView = false
    @State private var showStockToSaleView = false
    @State private var showGameSaleView = false
    @State private var showLicenseView = false
    @State private var showEditorView = false
    @State private var showPromoCodeView = false
    @State private var showBuyerSheet = false
    @State private var showSellerStatsView = false
    @State private var showBilanView = false
    
    init() {
        self.viewModel = ManageViewModel()
    }
    
    var body: some View {
        NavigationView {
            List {
                let items = viewModel.manageItems
                ForEach(items) { item in
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
            .sheet(isPresented: $showManagerCreationView) {
                ManagerView()
            }
            .sheet(isPresented: $showSessionView) {
                SessionView()
            }
            .sheet(isPresented: $showStockToSaleView) {
                GameStockToSaleView()
            }
            .sheet(isPresented: $showGameSaleView) {
                GameSaleView()
            }
            .sheet(isPresented: $showLicenseView) {
                LicenseView()
            }
            .sheet(isPresented: $showEditorView) {
                EditorView()
            }
            .sheet(isPresented: $showPromoCodeView) {
                PromoCodeView()
            }
            .sheet(isPresented: $showBuyerSheet) {
                BuyerView()
            .sheet(isPresented: $showSellerStatsView) {
                SellerStatsView()
            }
            .sheet(isPresented: $showBilanView) {
                BilanView()
            }
        }
    }
    
    private func handleAction(for item: ManageItem) {
        switch item.route {
        case "game/deposit":
            showDepositView = true
        case "seller":
            showSellerView = true
        case "seller/stats":
            showSellerStatsView = true
        case "manager/create":
            showManagerCreationView = true
        case "session/create":
            showSessionView = true
        case "game/stockToSale":
            showStockToSaleView = true
        case "game/sale":
            showGameSaleView = true
        case "license/manage":
            showLicenseView = true
        case "editor/manage":
            showEditorView = true
        case "code-promo":
            showPromoCodeView = true
        case "buyer/create":
            showBuyerSheet = true
        case "bilan":
            showBilanView = true
        default:
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
        case "license/manage": return "doc.badge.plus"
        case "editor/create": return "building.2.fill"
        case "game/stockToSale": return "arrow.right.square.fill"
        case "code-promo": return "tag.fill"
        case "bilan": return "chart.bar.fill"
        default: return "questionmark.circle.fill"
        }
    }
}
