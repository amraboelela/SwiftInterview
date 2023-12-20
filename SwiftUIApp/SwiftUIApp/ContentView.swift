//
//  ContentView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Build a NavigationView with NavigationLink

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            NavigationLink(destination: DetailView()) {
                Text("Go to Detail View")
            }
            .navigationBarTitle("Main View")
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("Detail View")
            .navigationBarTitle("Detail")
    }
}

#Preview {
    ContentView()
}
