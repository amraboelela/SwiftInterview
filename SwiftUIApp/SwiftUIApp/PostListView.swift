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
    let exampleUrl = URL(string: "https://example.com")!
    @State var message = "Loading..."
    
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
            var decodedData = try JSONDecoder().decode([Post].self, from: data)
            
            var receivedLines = [String]()
            for try await line in exampleUrl.lines {
                receivedLines.append(line)
                message = "Received \(receivedLines.count) lines"
                if decodedData.count > receivedLines.count {
                    decodedData[receivedLines.count].body = line
                }
            }
            
            let finalPosts = decodedData
            
            //try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            Task { @MainActor in
                posts = finalPosts
                
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
}

struct Post: Codable {
    let id: Int
    let title: String
    var body: String
}

#Preview {
    PostListView()
}
