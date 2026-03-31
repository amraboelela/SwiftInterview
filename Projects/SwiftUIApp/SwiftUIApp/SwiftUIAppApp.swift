//
//  SwiftUIAppApp.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

import SwiftUI
import RealmSwift

@main
struct SwiftUIAppApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            TaskListView()
        }
    }
    
    init() {
        // Set up Realm configuration
        let config = Realm.Configuration(schemaVersion: 2)
        do {
            let realm = try Realm(configuration: config)
            print("Realm file path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }
}
