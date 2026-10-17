//
//  BookAction.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct BookAction: Identifiable {
    let title: String
    let systemImage: String
    let tint: Color
    let perform: () async throws -> Void

    var id: String {
        title
    }

    static func borrow(_ book: Book,
                       using loanService: LoanService) -> BookAction {
        BookAction(title: "Borrow",
                   systemImage: "book",
                   tint: .green) {
            try await loanService.borrow(book)
        }
    }

    static func `return`(_ book: Book,
                         using loanService: LoanService) -> BookAction {
        BookAction(title: "Return",
                   systemImage: "arrow.uturn.backward",
                   tint: .orange) {
            try await loanService.returnBook(book)
        }
    }
}
