//
//  DeleteLoanErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct DeleteLoanErrorDTO: Decodable {
    enum CodeDTO: String, Decodable {
        case notBorrowed = "not_borrowed"
    }

    let error: CodeDTO
}
