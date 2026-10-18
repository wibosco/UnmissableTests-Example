//
//  LoanDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension LoanDTO {
    static func testData(book: BookDTO = .testData(),
                         borrowedDate: Date = Date(timeIntervalSince1970: 0),
                         dueDate: Date = Date(timeIntervalSince1970: 0)) -> LoanDTO {
        LoanDTO(book: book,
                borrowedDate: borrowedDate,
                dueDate: dueDate)
    }
}
