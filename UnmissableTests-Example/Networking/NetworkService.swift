//
//  NetworkService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol NetworkService {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
