//
//  Author.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

struct Author: Equatable, Sendable {
    let firstName: String
    let lastName: String

    var fullName: String {
        PersonNameComponents(givenName: firstName,
                             familyName: lastName).formatted()
    }
}
