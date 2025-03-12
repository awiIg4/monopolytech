//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                
                // App Title
                Text("MonoPolytech")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.primary)
                
                // Tagline
                Text("Plateforme de Vente de Jeux Vidéo")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("© 2025 MonoPolytech")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
