//
//  BookListResponse.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

struct BookListResponse: Encodable {
    let books: [BookRecord]
}
