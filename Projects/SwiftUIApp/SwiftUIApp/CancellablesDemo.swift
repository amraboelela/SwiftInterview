//
//  CancellablesDemo.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 4/12/26.
//

// Demonstrates how AnyCancellable cleanup works automatically via ARC.
// You do NOT need to call cancel() in deinit — it happens when the object deallocates.
// Manual cancellation is only needed when you want to stop BEFORE deallocation.

import Foundation
import Combine

// ✅ Automatic cleanup — subscriptions cancel when MyViewModel deallocates
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in print("tick") }
            .store(in: &cancellables)
    }

    // ⚠️ Manual cancellation — use when you need to stop BEFORE deallocation
    func stopListening() {
        cancellables.removeAll()
    }

    // ❌ This is NOT needed — ARC handles it automatically:
    // deinit {
    //     cancellables.forEach { $0.cancel() }
    //     cancellables.removeAll()
    // }
}
