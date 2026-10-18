//
//  RetrieveListingsErrorDTO.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated struct RetrieveListingsErrorDTO: Decodable {
    enum CodeDTO: String, Decodable {
        case catalogueUnavailable = "catalogue_unavailable"
    }

    let error: CodeDTO
}
