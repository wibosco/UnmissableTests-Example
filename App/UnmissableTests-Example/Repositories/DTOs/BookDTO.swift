//
//  BookDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

nonisolated struct BookDTO: Decodable {
    enum Status: String, Decodable {
        case available
        case onLoan = "on_loan"
        case onLoanToYou = "on_loan_to_you"
    }

    struct AuthorDTO: Decodable {
        let firstName: String
        let lastName: String
    }

    let id: String
    let title: String
    let author: AuthorDTO
    let isbn: String
    let coverImageName: String
    let availability: Status
}
