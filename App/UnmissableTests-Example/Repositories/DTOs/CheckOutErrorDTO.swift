//
//  CheckOutErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct CheckOutErrorDTO: Decodable {
    enum Code: String, Decodable {
        case alreadyBorrowed = "already_borrowed"
        case loanLimitReached = "loan_limit_reached"
        case bookUnavailable = "book_unavailable"
    }

    let error: Code
}
