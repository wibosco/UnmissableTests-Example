//
//  Book.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct Book: Equatable, Sendable {
    let id: String
    let title: String
    let author: Author
    let coverImageName: String
}
