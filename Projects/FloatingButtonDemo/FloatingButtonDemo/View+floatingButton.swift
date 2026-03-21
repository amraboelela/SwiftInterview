//
//  Button+floating.swift
//  FloatingButtonDemo
//
//  Created by Amr Aboelela on 3/21/26.
//

import SwiftUI

extension View {
    var floatingButton: some View {
        let options = ["Option 1", "Option 2", "Option 3"]
        return VStack {
            self
            List(options, id: \.self) { option in
                Button(
                    action: {
                        print("\(option) tapped")
                    },
                    label: {
                        Text(option)
                    }
                )
            }
        }
    }
}

#Preview {
    Text("Any Text")
        .floatingButton
}
