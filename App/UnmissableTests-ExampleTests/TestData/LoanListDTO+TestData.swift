//
//  LoanListDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension LoanListDTO {
    static func testData(loans: [LoanDTO] = []) -> LoanListDTO {
        LoanListDTO(loans: loans)
    }
}
