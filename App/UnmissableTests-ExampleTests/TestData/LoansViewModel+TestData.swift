//
//  LoansViewModel+TestData.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//
import Foundation

@testable import UnmissableTests_Example

extension LoansViewModel.Row {
    static func testData(id: String = "test_id",
                         title: String = "test_title",
                         authorName: String = "test_authorName",
                         coverImageName: String = "test_coverImageName",
                         dueDate: Date = Date(timeIntervalSince1970: 0),
                         isOverdue: Bool = false) -> LoansViewModel.Row {
        LoansViewModel.Row(id: id,
                           title: title,
                           authorName: authorName,
                           coverImageName: coverImageName,
                           dueDate: dueDate,
                           isOverdue: isOverdue)
    }
}

extension LoansViewModel.State {
    static func testData() -> LoansViewModel.State {
        .loading
    }
}

extension LoansViewModel.Alert {
    static func testData() -> LoansViewModel.Alert {
        .returnFailed
    }
}
