//
//  StubHTTPSession.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubHTTPSession: HTTPSession {
    enum Event: Equatable {
        case data(for: URLRequest)
    }

    private(set) var events = [Event]()

    var dataResponse: Result<(Data, URLResponse), any Error>!

    // MARK: - HTTPSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        events.append(.data(for: request))

        return try dataResponse.get()
    }
}
