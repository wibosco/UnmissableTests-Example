//
//  BookRecord.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

struct BookRecord: Encodable {
    enum Availability: String, Encodable {
        case available
        case onLoan = "on_loan"
        case onLoanToYou = "on_loan_to_you"
    }

    struct Author: Encodable {
        let firstName: String
        let lastName: String
    }

    let id: String
    let title: String
    let author: Author
    let isbn: String
    let coverImageName: String
    var availability: Availability
}
