//
//  CatalogueEntry.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct CatalogueEntry: Equatable, Sendable {
    let book: Book
    let availability: Availability
}
