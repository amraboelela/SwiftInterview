//
//  DetailView.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import SwiftUI

struct DetailView: View {
    @Binding var email: EmailMessage
    
    var body: some View {
        VStack {
            Text(email.message)
                .navigationBarTitle("Detail")
        }
        .onAppear {
            email.isRead = true
        }
    }
    
}
