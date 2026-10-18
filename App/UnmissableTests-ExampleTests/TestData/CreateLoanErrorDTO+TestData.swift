//
//  CreateLoanErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension CreateLoanErrorDTO {
    static func testData(error: CodeDTO = .testData()) -> CreateLoanErrorDTO {
        CreateLoanErrorDTO(error: error)
    }
}

nonisolated extension CreateLoanErrorDTO.CodeDTO {
    static func testData() -> CreateLoanErrorDTO.CodeDTO {
        .loanLimitReached
    }
}
