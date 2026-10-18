//
//  StubNetworkService.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubNetworkService: NetworkService {
    enum Event: Equatable {
        case send(URLRequest)
    }
    
    private(set) var events = [Event]()
    
    var sendResponse: Result<any Decodable & Sendable, any Error>!
    
    // MARK: - NetworkService
    
    func send<Success: Decodable & Sendable, Failure: Decodable & Sendable>(_ request: URLRequest,
                                                                            success: Success.Type,
                                                                            failure: Failure.Type) async throws(NetworkServiceError<Failure>) -> Success {
        events.append(.send(request))
        
        switch sendResponse! {
        case .success(let value):
            return value as! Success
        case .failure(let error):
            throw error as! NetworkServiceError<Failure>
        }
    }
}
