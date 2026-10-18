//
//  CheckInErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct CheckInErrorDTO: Codable {
    enum Code: String, Codable {
        case notBorrowed = "not_borrowed"
    }

    let error: Code
}
