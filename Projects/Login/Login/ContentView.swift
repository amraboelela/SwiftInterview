//
//  ContentView.swift
//  Login
//
//  Created by Amr Aboelela on 1/31/24.
//

import SwiftUI

struct ContentView: View {
    @State var username: String = ""
    @State var password: String = ""
    
    func login() {
        print("Handle the login, username: \(username), password: \(password)")
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Username")
                TextField("Username", text: $username)
            }
            HStack {
                Text("Password")
                SecureField("Password", text: $password)
            }
            Button(
                action: {
                    login()
                },
                label: { 
                    Text("Login")
                }
            )
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
