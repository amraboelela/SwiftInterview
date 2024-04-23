//
//  ContentViewModel.swift
//  QuickSearch
//
//  Created by Amr Aboelela on 4/23/24.
//

import Combine
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var messages = [String]()
    var fullMessages = [String]()
    
    var filteredMessages = [String]() /*{
        guard searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != "" else {
            //messages = fullMessages
            return fullMessages
        }
        var result = fullMessages.filter { message in
            return message.contains(searchText.lowercased())
        }
        return result
    }*/
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var searchText = ""
    
    //var myTextSearchPublisher: Publishers<String, Never> //AnyPublisher<String, Error>

    /*
          .publisher
          .sink { [weak self] (publishedValue) in
              //self?.title.text = publishedValue
          }
    .store(in: &cancellable)*/
    
    init() {
        fullMessages = ["message 1", "this is the second message", "the weather today is good", "what is the latestt news?", "president candedcy and so on stuff"]
        messages = fullMessages
        //myTextSearchPublisher = searchText.publisher
        $searchText
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] text in
                    self?.filterUsing(text: text)
                }
            )
            .store(in: &cancellables)
    }
    
    func filterUsing(text: String) {
        guard text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != "" else {
            filteredMessages = fullMessages
            return
        }
        filteredMessages = fullMessages.filter { message in
            return message.contains(text.lowercased())
        }
    }
}

