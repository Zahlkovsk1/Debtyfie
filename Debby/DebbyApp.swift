//
//  DebbyApp.swift
//  Debby
//
//  Created by Shox on 18/10/26.
//

import SwiftUI
import SwiftData

@main
struct DebbyApp: App {

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Person.self, Entry.self, PaymentCard.self])
    }
}
