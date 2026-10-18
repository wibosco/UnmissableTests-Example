//
//  HTTPSession.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

nonisolated protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {
    // `URLSession`'s own method takes a delegate with a default value, and a default value can't satisfy a
    // protocol requirement.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request,
                       delegate: nil)
    }
}
