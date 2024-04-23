//
//  ContentView.swift
//  QuickSearch
//
//  Created by Amr Aboelela on 4/23/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            TextField("Search message", text: $viewModel.searchText)
            /*.onChange(of: searchText) { oldText, newText in
             print(newText)
             viewModel.filterUsing(text: newText)
             }*/
            List(viewModel.filteredMessages, id:\.self) { message in
                Text(message)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}
