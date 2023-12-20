//
//  MailApp.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import SwiftUI

@main
struct MailApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MailCenter())
        }
    }
}
