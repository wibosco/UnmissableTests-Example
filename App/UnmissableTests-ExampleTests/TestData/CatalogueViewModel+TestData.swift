//
//  CatalogueViewModel+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension CatalogueViewModel.Row {
    static func testData(id: String = "test_id",
                         title: String = "test_title",
                         authorName: String = "test_authorName",
                         coverImageName: String = "test_coverImageName",
                         availability: Availability = .testData()) -> CatalogueViewModel.Row {
        CatalogueViewModel.Row(id: id,
                              title: title,
                              authorName: authorName,
                              coverImageName: coverImageName,
                              availability: availability)
    }
}

extension CatalogueViewModel.Row.Availability {
    static func testData() -> CatalogueViewModel.Row.Availability {
        .available
    }
}

extension CatalogueViewModel.State {
    static func testData() -> CatalogueViewModel.State {
        .loading
    }
}

extension CatalogueViewModel.Alert {
    static func testData() -> CatalogueViewModel.Alert {
        .loanLimitReached
    }
}
