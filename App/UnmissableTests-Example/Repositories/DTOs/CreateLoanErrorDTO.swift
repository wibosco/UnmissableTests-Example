//
//  CreateLoanErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct CreateLoanErrorDTO: Decodable {
    enum CodeDTO: String, Decodable {
        case loanLimitReached = "loan_limit_reached"
        case bookUnavailable = "book_unavailable"
    }

    let error: CodeDTO
}
