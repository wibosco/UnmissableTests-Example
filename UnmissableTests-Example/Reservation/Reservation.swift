//
//  Reservation.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct Reservation: Equatable, Sendable {
    let book: Book
    let reservedAt: Date
}
