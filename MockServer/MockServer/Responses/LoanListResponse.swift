//
//  LoanListResponse.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

struct LoanListResponse: Encodable {
    let loans: [LoanResponse]
}
