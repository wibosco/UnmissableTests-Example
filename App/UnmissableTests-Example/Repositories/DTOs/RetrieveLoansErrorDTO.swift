//
//  RetrieveLoansErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct RetrieveLoansErrorDTO: Decodable {
    enum CodeDTO: String, Decodable {
        case membershipExpired = "membership_expired"
    }

    let error: CodeDTO
}
