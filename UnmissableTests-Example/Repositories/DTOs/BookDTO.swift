//
//  BookDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct BookDTO: Codable {
    enum Status: String, Codable {
        case available
        case onLoan = "on_loan"
        case onLoanToYou = "on_loan_to_you"
    }

    struct AuthorResponse: Codable {
        let firstName: String
        let lastName: String
    }

    let id: String
    let title: String
    let author: AuthorResponse
    let isbn: String
    let coverImageName: String
    let availability: Status
}
