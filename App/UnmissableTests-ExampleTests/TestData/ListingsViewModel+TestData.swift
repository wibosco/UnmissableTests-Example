//
//  ListingsViewModel+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension ListingsViewModel.Row {
    static func testData(id: String = "test_id",
                         title: String = "test_title",
                         authorName: String = "test_authorName",
                         coverImageName: String = "test_coverImageName",
                         availability: Availability = .testData(),
                         action: Action? = .testData()) -> ListingsViewModel.Row {
        ListingsViewModel.Row(id: id,
                              title: title,
                              authorName: authorName,
                              coverImageName: coverImageName,
                              availability: availability,
                              action: action)
    }
}

extension ListingsViewModel.Row.Availability {
    static func testData() -> ListingsViewModel.Row.Availability {
        .available
    }
}

extension ListingsViewModel.Row.Action {
    static func testData() -> ListingsViewModel.Row.Action {
        .borrow
    }
}

extension ListingsViewModel.State {
    static func testData() -> ListingsViewModel.State {
        .loading
    }
}

extension ListingsViewModel.Alert {
    static func testData() -> ListingsViewModel.Alert {
        .loanLimitReached
    }
}
