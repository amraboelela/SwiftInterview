//
//  UserInputFormView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Implement a Form with TextField and Button

import SwiftUI

struct UserInputFormView: View {
    @State private var userInput = ""
    
    var body: some View {
        Form {
            TextField("Enter text", text: $userInput)
            Button(
                action: {
                    // Perform action with userInput
                    print("User input: \(userInput)")
                }, 
                label: {
                    Text("Submit")
                }
            )
        }
    }
}

#Preview {
    UserInputFormView()
}
