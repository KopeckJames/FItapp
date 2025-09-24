//
//  FItappApp.swift
//  FItapp
//
//  Created by James Kopeck on 9/24/25.
//

import SwiftUI

@main
struct FItappApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
