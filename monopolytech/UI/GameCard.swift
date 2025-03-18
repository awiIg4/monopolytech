//
//  GameCard.swift
//  monopolytech
//
//  Created by eugenio on 13/03/2025.
//

import SwiftUI

struct GameCard: View {

    let game: Game
    var onTap: ((Game) -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?(game)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Game title
                Text(game.licence_name ?? "Unknown Game")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Price
                Text("\(formatPrice(game.prix)) €")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                // Status if available
                if let status = game.statut {
                    Text("Status: \(status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

struct GameCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GameCard(game: Game.placeholder)
                .padding()
            
            // Grid preview
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(Game.placeholders) { game in
                    GameCard(game: game)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
