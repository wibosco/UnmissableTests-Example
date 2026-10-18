//
//  BookListDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension BookListDTO {
    static func testData(books: [BookDTO] = []) -> BookListDTO {
        BookListDTO(books: books)
    }
}
