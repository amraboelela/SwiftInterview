//
//  ContentView.swift
//  FloatingButtonDemo
//
//  Created by Amr Aboelela on 3/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var items: [String] = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        NavigationStack {
            List(items, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("FloatingButton Demo")
        }
        .floatingButton(
            options: [
                FloatingButtonOption(label: "Add Item", systemImage: "plus.circle") {
                    items.append("Item \(items.count + 1)")
                },
                FloatingButtonOption(label: "Camera", systemImage: "camera") {
                    print("Camera tapped")
                },
                FloatingButtonOption(label: "Share", systemImage: "square.and.arrow.up") {
                    print("Share tapped")
                }
            ]
        )
    }
}

#Preview {
    ContentView()
}
