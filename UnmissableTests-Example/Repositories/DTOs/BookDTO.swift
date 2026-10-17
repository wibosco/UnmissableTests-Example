//
//  BookDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct BookDTO: Decodable {
    enum Status: String, Decodable {
        case available
        case onLoan = "on_loan"
        case onLoanToYou = "on_loan_to_you"
    }

    struct AuthorResponse: Decodable {
        let firstName: String
        let lastName: String
    }

    let id: String
    let title: String
    let author: AuthorResponse
    let isbn: String
    let coverImageName: String
    let availability: Status

    var listing: Listing {
        Listing(book: book,
                availability: mappedAvailability)
    }

    private var book: Book {
        Book(id: id,
             title: title,
             author: Author(firstName: author.firstName,
                            lastName: author.lastName),
             coverImageName: coverImageName)
    }

    private var mappedAvailability: Availability {
        switch availability {
        case .available:
            .available
        case .onLoan:
            .onLoan
        case .onLoanToYou:
            .onLoanToYou
        }
    }
}
