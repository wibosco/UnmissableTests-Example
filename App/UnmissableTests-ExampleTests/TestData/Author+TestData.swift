//
//  Author+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension Author {
    static func testData(firstName: String = "test_firstName",
                         lastName: String = "test_lastName") -> Author {
        Author(firstName: firstName,
               lastName: lastName)
    }
}
