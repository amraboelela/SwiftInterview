//
//  PostListView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Fetch and Display Data from an API in SwiftUI

import SwiftUI

struct PostListView: View {
    @State private var posts: [Post] = []

    var body: some View {
        List(posts, id: \.id) { post in
            VStack(alignment: .leading) {
                Text("\(post.id). \(post.title)")
                    .font(.headline)
                Text(post.body)
                    .foregroundColor(.gray)
            }
        }
        .task {
            // Fetch data from API and update posts
            await fetchData()
        }
    }

    private func fetchData() async {
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode([Post].self, from: data)
            //try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            Task { @MainActor in
                posts = decodedData
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
}

struct Post: Codable {
    let id: Int
    let title: String
    let body: String
}

#Preview {
    PostListView()
}
