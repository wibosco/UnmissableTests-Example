//
//  RetrieveListingsErrorDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

nonisolated extension RetrieveListingsErrorDTO {
    static func testData(error: CodeDTO = .testData()) -> RetrieveListingsErrorDTO {
        RetrieveListingsErrorDTO(error: error)
    }
}

nonisolated extension RetrieveListingsErrorDTO.CodeDTO {
    static func testData() -> RetrieveListingsErrorDTO.CodeDTO {
        .catalogueUnavailable
    }
}
