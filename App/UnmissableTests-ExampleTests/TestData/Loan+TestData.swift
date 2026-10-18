//
//  Loan+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension Loan {
    static func testData(book: Book = .testData(),
                         dueDate: Date = Date(timeIntervalSince1970: 0)) -> Loan {
        Loan(book: book,
             dueDate: dueDate)
    }
}
