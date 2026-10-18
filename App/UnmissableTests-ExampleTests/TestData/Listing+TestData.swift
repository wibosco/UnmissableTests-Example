//
//  Listing+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension Listing {
    static func testData(book: Book = .testData(),
                         availability: Availability = .testData()) -> Listing {
        Listing(book: book,
                availability: availability)
    }
}
