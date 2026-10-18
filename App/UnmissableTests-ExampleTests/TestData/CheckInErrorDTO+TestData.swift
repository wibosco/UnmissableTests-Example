//
//  CheckInErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension CheckInErrorDTO {
    static func testData(error: Code = .testData()) -> CheckInErrorDTO {
        CheckInErrorDTO(error: error)
    }
}

nonisolated extension CheckInErrorDTO.Code {
    static func testData() -> CheckInErrorDTO.Code {
        .notBorrowed
    }
}
