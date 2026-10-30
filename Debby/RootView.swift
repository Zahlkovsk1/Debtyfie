//
//  RootView.swift
//  Debby
//
//  Created by Shox on 22/10/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Main", systemImage: "house") {
                HomeView()
            }
            
            Tab("Owed", systemImage: "scalemass") {
                       NavigationStack {
                           OwedView()
                       }
                   }
            
            Tab("Statistics", systemImage: "chart.bar") {
                StatsView()
            }
            
        }
        .tint(.textPrimary)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
