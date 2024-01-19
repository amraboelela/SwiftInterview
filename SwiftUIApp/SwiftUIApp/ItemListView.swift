//
//  ItemListView.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Create a List of Items using ForEach

import SwiftUI

struct ItemListView: View {
    let items = ["Item 1", "Item 2", "Item 3", "Amr"]
    
    var body: some View {
        List (items, id: \.self) { item in
            Text(item)
        }
    }
}

#Preview {
    ItemListView()
}
