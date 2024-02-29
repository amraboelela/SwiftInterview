//
//  HelloWorld.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Create a SwiftUI View with Text that displays "Hello, World!"

import SwiftUI

struct HelloWorld: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .foregroundColor(nil)
                .foregroundColor(.red)
        }
        .padding()
    }
}

#Preview {
    HelloWorld()
}
