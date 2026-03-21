//
//  ContentView.swift
//  FloatingButtonDemo
//
//  Created by Amr Aboelela on 3/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button(
                action: {
                    print("button tapped")
                },
                label: {
                    Text("Demo")
                }
            )
            .floatingButton
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
