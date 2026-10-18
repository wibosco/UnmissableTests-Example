//
//  LoanResponse.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

struct LoanResponse: Encodable {
    let book: BookRecord
    let borrowedDate: Date
    let dueDate: Date

    init(book: BookRecord,
         loan: LoanRecord) {
        self.book = book
        self.borrowedDate = loan.borrowedDate
        self.dueDate = loan.dueDate
    }
}
