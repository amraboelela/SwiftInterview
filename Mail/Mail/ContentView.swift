//
//  ContentView.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mailCenter: MailCenter
    
    var body: some View {
        NavigationView {
            List(mailCenter.emails) { email in
                NavigationLink(destination: DetailView(email: email)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Circle()
                                .fill(email.isRead ? Color.white : Color.blue)
                                .stroke(Color.blue, lineWidth: 1)
                                .frame(width: 10, height: 10)
                            Image(systemName: "flag")
                                .imageScale(.small)
                                .foregroundStyle(.tint)
                            Text(email.subject)
                                .font(Font.title2.weight(.bold))
                        }
                        Text(email.message)
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
