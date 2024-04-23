//
//  QuickSearchApp.swift
//  QuickSearch
//
//  Created by Amr Aboelela on 4/23/24.
//

import SwiftUI

@main
struct QuickSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel())
        }
    }
}
