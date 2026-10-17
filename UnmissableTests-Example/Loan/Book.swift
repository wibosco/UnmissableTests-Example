//
//  Book.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct Book: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let author: Author
    let isbn: String
    let coverImageName: String
}
