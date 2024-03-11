//
//  ToggleButtonView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Implement a Button that toggles a boolean state variable

import SwiftUI

struct ToggleButtonView: View {
    @State private var isToggled = false
    
    var body: some View {
        Button(
            action: {
                isToggled.toggle()
            },
            label: {
                Text("Toggle: \(isToggled ? "On" : "Off")")
            }
        )
        .padding()
    }
}

#Preview {
    ToggleButtonView()
}
