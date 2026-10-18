//
//  CheckInErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct CheckInErrorDTO: Decodable {
    enum Code: String, Decodable {
        case notBorrowed = "not_borrowed"
    }

    let error: Code
}
