//
//  CheckOutErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension CheckOutErrorDTO {
    static func testData(error: Code = .testData()) -> CheckOutErrorDTO {
        CheckOutErrorDTO(error: error)
    }
}

nonisolated extension CheckOutErrorDTO.Code {
    static func testData() -> CheckOutErrorDTO.Code {
        .alreadyBorrowed
    }
}
