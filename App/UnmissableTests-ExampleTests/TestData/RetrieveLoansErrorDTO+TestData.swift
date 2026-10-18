//
//  RetrieveLoansErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

nonisolated extension RetrieveLoansErrorDTO {
    static func testData(error: CodeDTO = .testData()) -> RetrieveLoansErrorDTO {
        RetrieveLoansErrorDTO(error: error)
    }
}

nonisolated extension RetrieveLoansErrorDTO.CodeDTO {
    static func testData() -> RetrieveLoansErrorDTO.CodeDTO {
        .membershipExpired
    }
}
