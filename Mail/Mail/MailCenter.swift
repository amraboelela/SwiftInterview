//
//  MailFetch.swift
//  Mail
//
//  Created by Amr Aboelela on 12/20/23.
//

import Foundation

struct EmailMessage: Hashable, Identifiable {
    let id: UUID
    let from: String
    let to: String
    let subject: String
    let message: String
    let formattedDate: String
    var isRead: Bool = false
}

struct MailFetch {
    
    static func fetchNewMail(count: Int) -> [EmailMessage] {
        
        let InvestingSpam = [
            "Dear Fellow Investor Heres something only a handful of people know - On March 19 2023 AI discovered a new drug for liver cancer in only 30 days",
            "Financial leaders like Ray Dalio Stanley Druckenmiller and David Tepper have silently sunk millions into the AI sector and these ventures",
            "On December 22 2022 AI discovered a new treatment for multiple myeloma in just 4 months",
            "When he made his first 100000 trading penny stocks with zero financial experience they told him he got lucky"
        ]
        
        let spammers = [
            "support@gorgeousincome.com",
            "seven@daily.the7at7.com"
        ]
        
        precondition(count > 0)
        var newMail: [EmailMessage] = []
        
        
        let subjects = [
            "AI stock's 1,029% month!",
            "Top Stocks to Profit from the ChatGPT",
            "Today's Top Optionable Stocks: MU, TSM and more",
            "Traders blog"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let fmtDate = dateFormatter.string(from: Date())
        
        let to = "dxc@dxc.com"
        for _ in 0..<count {
            let message = EmailMessage(
                id: UUID(),
                from: spammers.randomElement()!,
                to: to,
                subject: subjects.randomElement()!,
                message:  InvestingSpam.randomElement()!,
                formattedDate: fmtDate)
            newMail.append(message)
        }
        
        return newMail
    }
    
}

class MailCenter: ObservableObject {
    @Published var emails = [EmailMessage]()
    
    func fetchEmails() {
        emails = MailFetch.fetchNewMail(count: 5)
    }
    
    func markAsRead(id: UUID) {
        for i in 0..<emails.count {
            if emails[i].id == id {
                emails[i].isRead = true
                return
            }
        }
    }
}

