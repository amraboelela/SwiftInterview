//
//  ContentView.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import SwiftUI

struct ContentView: View {
    //@EnvironmentObject var mailCenter: MailCenter
    @ObservedObject var mailCenter: MailCenter
    
    var body: some View {
        NavigationView {
            List(mailCenter.emails.indices, id: \.self) { index in
                NavigationLink(
                    destination: DetailView(
                        email: mailCenter.emailBinding(forIndex: index)
                    )
                ) {
                    VStack(alignment: .leading) {
                        HStack {
                            Circle()
                                .fill(mailCenter.emails[index].isRead ? Color.white : Color.blue)
                                //.stroke(Color.blue, lineWidth: 1)
                                .frame(width: 10, height: 10)
                            Image(systemName: "flag")
                                .imageScale(.small)
                                .foregroundStyle(.tint)
                            Text(mailCenter.emails[index].subject)
                                .font(Font.title2.weight(.bold))
                        }
                        Text(mailCenter.emails[index].message)
                            .font(Font.body)
                    }
                }
            }
            .navigationBarTitle("Mails")
        }
        .onAppear {
            mailCenter.fetchEmails()
        }
    }
}

#Preview {
    ContentView(mailCenter: MailCenter())
}
