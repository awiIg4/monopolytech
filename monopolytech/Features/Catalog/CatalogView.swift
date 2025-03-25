//
//  CatalogView.swift
//  monopolytech
//
//  Created by hugo on 18/03/2024.
//

import SwiftUI

/// Vue principale du catalogue présentant la liste des jeux disponibles
struct CatalogView: View {
    @StateObject private var viewModel = CatalogViewModel()
    @State private var searchText = ""
    @State private var showPriceFilter = false
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 100
    @State private var selectedGame: Game? = nil
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Section de recherche et filtres
                VStack(spacing: 8) {
                    // Barre de recherche améliorée
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Rechercher un jeu...", text: $searchText)
                            .padding(8)
                            .submitLabel(.search)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { newValue in
                                if newValue.isEmpty {
                                    viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
                                }
                            }
                            .onSubmit {
                                if !searchText.isEmpty {
                                    viewModel.searchGames(query: searchText, minPrice: minPrice, maxPrice: maxPrice)
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Bouton de filtre par prix
                    Button(action: { showPriceFilter.toggle() }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Filtrer par prix")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Vue du filtre de prix
                    if showPriceFilter {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Prix min: \(Int(minPrice))€")
                                Spacer()
                                Text("Prix max: \(Int(maxPrice))€")
                            }
                            .font(.caption)
                            
                            HStack(spacing: 8) {
                                Slider(
                                    value: $minPrice,
                                    in: 0...maxPrice,
                                    onEditingChanged: { editing in
                                        if !editing { // Le slider a été relâché
                                            updateSearch()
                                        }
                                    }
                                )
                                Slider(
                                    value: $maxPrice,
                                    in: minPrice...100,
                                    onEditingChanged: { editing in
                                        if !editing { // Le slider a été relâché
                                            updateSearch()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.slide)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 2, y: 2)
                
                // Grille de jeux ou indicateur de chargement
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement des jeux...")
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Erreur de chargement")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Réessayer") {
                            viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                    }
                    .padding()
                    Spacer()
                } else if viewModel.games.isEmpty {
                    Spacer()
                    Text("Aucun jeu trouvé")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.games) { game in
                                GameCard(game: game) { selectedGame in
                                    self.selectedGame = selectedGame
                                }
                            }
                        }
                        .padding()
                        
                        // Contrôles de pagination
                        if !viewModel.games.isEmpty {
                            HStack(spacing: 20) {
                                Button(action: {
                                    viewModel.loadPreviousPage(minPrice: minPrice, maxPrice: maxPrice)
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(viewModel.currentPage > 1 ? .blue : .gray)
                                }
                                .disabled(viewModel.currentPage <= 1)
                                
                                Text("Page \(viewModel.currentPage)")
                                    .font(.caption)
                                
                                Button(action: {
                                    viewModel.loadNextPage(minPrice: minPrice, maxPrice: maxPrice)
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(viewModel.hasNextPage ? .blue : .gray)
                                }
                                .disabled(!viewModel.hasNextPage)
                            }
                            .padding(.vertical)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Catalogue")
            .onAppear {
                viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
            }
            .animation(.easeInOut, value: showPriceFilter)
            .sheet(item: $selectedGame) { game in
                GameDetailView(game: game)
            }
        }
    }
    
    /// Exécute la recherche en fonction du texte saisi
    private func performSearch() {
        if searchText.isEmpty {
            viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
        } else {
            viewModel.searchGames(query: searchText, minPrice: minPrice, maxPrice: maxPrice)
        }
    }
    
    /// Met à jour la recherche en fonction des filtres de prix
    private func updateSearch() {
        if searchText.isEmpty {
            viewModel.loadGames(minPrice: minPrice, maxPrice: maxPrice)
        } else {
            viewModel.searchGames(query: searchText, minPrice: minPrice, maxPrice: maxPrice)
        }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView()
    }
}

