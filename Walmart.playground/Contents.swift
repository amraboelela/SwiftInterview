import SwiftUI
import PlaygroundSupport

import SwiftUI

struct LoginScreen: View {
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding(.bottom)

            TextField("Username", text: $username)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .padding(.horizontal)

            Button("Login") {
                // Create a network request to authenticate the user
                var request = URLRequest(url: URL(string: "https://example.com/login")!)

                // Set the request method and HTTP headers
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                // Create a JSON body for the request
                let body = try? JSONEncoder().encode(["username": username, "password": password])

                // Make the network request
                URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
                    // Check if the request was successful
                    if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                        // The login was successful

                        // Navigate to the next screen
                        // ...
                    } else {
                        // The login failed

                        // Display an error message
                        // ...
                    }
                }.resume()
            }
            .padding(.top)
        }
    }
}


// Create an instance of the LoginView and display it in the Live View
let loginView = LoginScreen()
PlaygroundPage.current.setLiveView(loginView)

//let loginView = LoginScreen()
//
//let hostingController = UIHostingController(rootView: loginView)
//PlaygroundPage.current.liveView = hostingController
