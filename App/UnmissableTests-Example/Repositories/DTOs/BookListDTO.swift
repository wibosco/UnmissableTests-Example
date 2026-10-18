//
//  BookListDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct BookListDTO: Decodable {
    let books: [BookDTO]
}
