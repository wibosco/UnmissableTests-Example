//
//  ErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct ErrorDTO: Codable {
    enum Code: String, Codable {
        case alreadyBorrowed = "already_borrowed"
        case loanLimitReached = "loan_limit_reached"
        case bookUnavailable = "book_unavailable"
        case notBorrowed = "not_borrowed"
    }

    let error: Code
}
