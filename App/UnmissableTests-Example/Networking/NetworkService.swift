//
//  NetworkService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum NetworkServiceError<Failure: Decodable & Sendable>: Error {
    case requestFailed
    case unacceptableStatusCode(Int)
    case failureResponse(Failure)
    case decodingFailed
}

protocol NetworkService {
    func send<Success: Decodable & Sendable, Failure: Decodable & Sendable>(_ request: URLRequest,
                                                                            success: Success.Type,
                                                                            failure: Failure.Type) async throws(NetworkServiceError<Failure>) -> Success
}

final class DefaultNetworkService: NetworkService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let acceptableStatusCodes = 200..<300

    // MARK: - Init

    init(session: URLSession) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Send

    func send<Success: Decodable & Sendable, Failure: Decodable & Sendable>(_ request: URLRequest,
                                                                            success: Success.Type,
                                                                            failure: Failure.Type) async throws(NetworkServiceError<Failure>) -> Success {
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .requestFailed
        }

        guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
            if let failureResponse = try? decoder.decode(failure,
                                                         from: data) {
                throw .failureResponse(failureResponse)
            }

            throw .unacceptableStatusCode(httpResponse.statusCode)
        }

        guard let successResponse = try? decoder.decode(success,
                                                        from: data) else {
            throw .decodingFailed
        }

        return successResponse
    }
}
