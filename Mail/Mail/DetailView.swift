//
//  DetailView.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject var mailCenter: MailCenter
    var email: EmailMessage
    
    var body: some View {
        VStack {
            Text(email.message)
                .navigationBarTitle("Detail")
        }
        .onAppear {
            mailCenter.markAsRead(id: email.id)
        }
    }
    
}
