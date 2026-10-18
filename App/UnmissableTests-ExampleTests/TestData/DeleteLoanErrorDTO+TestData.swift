//
//  DeleteLoanErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension DeleteLoanErrorDTO {
    static func testData(error: CodeDTO = .testData()) -> DeleteLoanErrorDTO {
        DeleteLoanErrorDTO(error: error)
    }
}

nonisolated extension DeleteLoanErrorDTO.CodeDTO {
    static func testData() -> DeleteLoanErrorDTO.CodeDTO {
        .notBorrowed
    }
}
