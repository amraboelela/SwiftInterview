//
//  CustomCard.swift
//  SwiftUIApp
//
//  Created by Amr Aboelela on 12/19/23.
//

// Create a Custom SwiftUI View

import SwiftUI

struct CustomCard: View {
    let imageName: String
    let title: String
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            
            Text(title)
                .font(.largeTitle)
        }
    }
}

#Preview {
    CustomCard(imageName: "pencil", title: "Pencil")
}
