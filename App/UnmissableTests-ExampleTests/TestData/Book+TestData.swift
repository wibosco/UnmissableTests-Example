//
//  Book+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension Book {
    static func testData(id: String = "test_id",
                         title: String = "test_title",
                         author: Author = .testData(),
                         coverImageName: String = "test_coverImageName") -> Book {
        Book(id: id,
             title: title,
             author: author,
             coverImageName: coverImageName)
    }
}
