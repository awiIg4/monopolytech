//
//  CommonUIComponents.swift
//  monopolytech
//
//  Created by eugenio on 21/03/2025.
//

import SwiftUI

/// Champ de texte personnalisé avec icône
public struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    public init(text: Binding<String>, placeholder: String, icon: String, keyboardType: UIKeyboardType = .default) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
    }
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/// Champ sécurisé avec icône pour les mots de passe
public struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    public init(text: Binding<String>, placeholder: String, icon: String) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
    }
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/// Ligne d'information avec titre, valeur et icône optionnelle
public struct InfoRow: View {
    let title: String
    let value: String
    var icon: String? = nil
    
    public init(title: String, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

/// Ligne de statistique pour les tableaux de bord
public struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public init(title: String, value: String, icon: String, color: Color = .primary) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .fontWeight(.medium)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Supprimer complètement cette structure ou la commenter
/*
/// Carte d'élément de gestion pour le menu
public struct ManageItemCard: View {
    let item: ManageItem
    
    public init(item: ManageItem) {
        self.item = item
    }
    
    public var body: some View {
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
*/
