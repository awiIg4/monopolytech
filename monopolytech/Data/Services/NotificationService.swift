//
//  NotificationService.swift
//  monopolytech
//
//  Created by eugenio on 17/03/2025.
//

import SwiftUI
import Combine

/// Représente une notification ou un message toast
struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    
    /// Type de notification avec une apparence spécifique
    enum ToastType {
        case success, error, info
        
        /// Couleur associée au type de notification
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        /// Icône associée au type de notification
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

/// Service pour gérer les notifications et les erreurs
class NotificationService: ObservableObject {
    /// Instance partagée pour toute l'application
    static let shared = NotificationService()
    private init() {} // Pattern Singleton
    
    /// Toast actuel à afficher
    @Published var currentToast: ToastMessage?
    
    /// Affiche une notification de succès
    /// - Parameter message: Message à afficher
    func showSuccess(_ message: String) {
        currentToast = ToastMessage(message: message, type: .success)
    }
    
    /// Affiche une notification d'erreur
    /// - Parameter error: Erreur à afficher
    func showError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        currentToast = ToastMessage(message: message, type: .error)
    }
    
    /// Affiche une notification d'information
    /// - Parameter message: Message à afficher
    func showInfo(_ message: String) {
        currentToast = ToastMessage(message: message, type: .info)
    }
}

/// Modificateur de vue pour afficher les messages toast
struct ToastModifier: ViewModifier {
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = notificationService.currentToast {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: toast.type.icon)
                                Text(toast.message)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(toast.type.color.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                workItem?.cancel()
                                
                                let task = DispatchWorkItem {
                                    withAnimation {
                                        notificationService.currentToast = nil
                                    }
                                }
                                
                                workItem = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: notificationService.currentToast != nil)
            )
    }
}

extension View {
    /// Ajoute la fonctionnalité de toast à n'importe quelle vue
    func toastMessage() -> some View {
        self.modifier(ToastModifier())
    }
}
