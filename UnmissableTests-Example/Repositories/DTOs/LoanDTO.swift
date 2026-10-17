//
//  LoanDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct LoanDTO: Decodable {
    let bookId: String
    let borrowedAt: Date
    let dueDate: Date
}
