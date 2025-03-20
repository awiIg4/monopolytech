//
//  GameCard.swift
//  monopolytech
//
//  Created by hugo on 18/03/2024.
//

import SwiftUI

struct GameCard: View {

    let game: Game
    var onTap: ((Game) -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?(game)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Header avec titre et indicateur de statut
                HStack(alignment: .top) {
                    // Game title
                    Text(game.licence_name ?? "Unknown Game")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .frame(height: 45)
                    
                    Spacer()
                    
                    // Statut indicator
                    Circle()
                        .fill(game.statut == "available" ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                    .frame(height: 4)
                
                // Price
                Text("\(formatPrice(game.prix)) €")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
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
