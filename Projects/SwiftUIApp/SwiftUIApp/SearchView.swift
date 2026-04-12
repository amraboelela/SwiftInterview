//
//  SearchView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 4/12/26.
//

// Demonstrates .debounce from Combine — waits until the user stops typing
// before firing a search, avoiding a request on every keystroke.

import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fetchResults(for: query)
            }
            .store(in: &cancellables)
    }

    private func fetchResults(for query: String) {
        results = query.isEmpty ? [] : ["Result for \(query)"]
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack {
            TextField("Search...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(viewModel.results, id: \.self) { result in
                Text(result)
            }
        }
        .navigationTitle("Search")
    }
}

#Preview {
    SearchView()
}
