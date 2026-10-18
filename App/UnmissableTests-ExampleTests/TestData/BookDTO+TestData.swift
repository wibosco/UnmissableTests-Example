//
//  BookDTO+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

nonisolated extension BookDTO {
    static func testData(id: String = "test_id",
                         title: String = "test_title",
                         author: AuthorDTO = .testData(),
                         isbn: String = "test_isbn",
                         coverImageName: String = "test_coverImageName",
                         availability: AvailabilityDTO = .testData()) -> BookDTO {
        BookDTO(id: id,
                title: title,
                author: author,
                isbn: isbn,
                coverImageName: coverImageName,
                availability: availability)
    }
}

nonisolated extension BookDTO.AvailabilityDTO {
    static func testData() -> BookDTO.AvailabilityDTO {
        .available
    }
}

nonisolated extension BookDTO.AuthorDTO {
    static func testData(firstName: String = "test_firstName",
                         lastName: String = "test_lastName") -> BookDTO.AuthorDTO {
        BookDTO.AuthorDTO(firstName: firstName,
                          lastName: lastName)
    }
}
