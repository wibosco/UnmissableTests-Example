//
//  ErrorResponse.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

struct ErrorResponse: Encodable {
    let error: String
    let message: String
}
