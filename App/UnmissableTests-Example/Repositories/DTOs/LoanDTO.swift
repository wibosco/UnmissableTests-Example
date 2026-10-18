//
//  LoanDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

nonisolated struct LoanDTO: Decodable {
    let book: BookDTO
    let borrowedDate: Date
    let dueDate: Date
}
