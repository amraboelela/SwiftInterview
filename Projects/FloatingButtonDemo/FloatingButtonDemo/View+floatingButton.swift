//
//  View+floatingButton.swift
//  FloatingButtonDemo
//
//  Created by Amr Aboelela on 3/21/26.
//

import SwiftUI

struct FloatingButtonOption {
    let label: String
    let systemImage: String
    let action: () -> Void
}

struct FloatingButtonModifier: ViewModifier {
    let options: [FloatingButtonOption]
    @State private var isExpanded = false

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            VStack(alignment: .trailing, spacing: 12) {
                if isExpanded {
                    ForEach(options, id: \.label) { option in
                        Button(
                            action: {
                                option.action()
                                withAnimation(.spring()) {
                                    isExpanded = false
                                }
                            },
                            label: {
                                HStack(spacing: 8) {
                                    Text(option.label)
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial)
                                        .clipShape(Capsule())
                                    Image(systemName: option.systemImage)
                                        .frame(width: 44, height: 44)
                                        .background(Color.accentColor)
                                        .foregroundStyle(.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 3)
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                Button(
                    action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    },
                    label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            .animation(.spring(), value: isExpanded)
                    }
                )
            }
            .padding()
        }
    }
}

extension View {
    func floatingButton(options: [FloatingButtonOption]) -> some View {
        modifier(FloatingButtonModifier(options: options))
    }
}

#Preview {
    Text("Any content here")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .floatingButton(
            options: [
                FloatingButtonOption(label: "Camera", systemImage: "camera") { print("Camera tapped") },
                FloatingButtonOption(label: "Photo",  systemImage: "photo")  { print("Photo tapped") },
                FloatingButtonOption(label: "File",   systemImage: "doc")    { print("File tapped") }
            ]
        )
}
