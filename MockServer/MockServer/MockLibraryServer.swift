//
//  MockLibraryServer.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

/// Stands in for the library API. The catalogue and loans are seeded from JSON files into an in-memory library,
/// which borrowing and returning then change for as long as the app runs.
public final class MockLibraryServer: URLProtocol {
    private enum Route {
        case books
        case loans
        case createLoan(bookID: String)
        case deleteLoan(bookID: String)

        init?(request: URLRequest) {
            guard let url = request.url else {
                return nil
            }

            let path = Array(url.pathComponents.dropFirst())

            switch request.httpMethod ?? "GET" {
            case "GET" where path == ["books"]:
                self = .books
            case "GET" where path == ["loans"]:
                self = .loans
            case "PUT" where path.count == 2 && path[0] == "loans":
                self = .createLoan(bookID: path[1])
            case "DELETE" where path.count == 2 && path[0] == "loans":
                self = .deleteLoan(bookID: path[1])
            default:
                return nil
            }
        }
    }

    // MARK: - Session

    public static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLibraryServer.self]

        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol

    public override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    public override func startLoading() {
        do {
            let (data, response) = try respond(to: request)

            client?.urlProtocol(self,
                                didReceive: response,
                                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self,
                                didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self,
                                didFailWithError: error)
        }
    }

    public override func stopLoading() {}

    // MARK: - Responses

    private func respond(to request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        guard let route = Route(request: request) else {
            return try response(for: url,
                                statusCode: 404)
        }

        let library = LibraryStore.shared

        do {
            switch route {
            case .books:
                return try response(for: url,
                                    statusCode: 200,
                                    body: BookListResponse(books: library.retrieveBooks()))
            case .loans:
                return try response(for: url,
                                    statusCode: 200,
                                    body: LoanListResponse(loans: library.retrieveLoans()))
            case .createLoan(let bookID):
                return try response(for: url,
                                    statusCode: 200,
                                    body: library.createLoan(forBookID: bookID))
            case .deleteLoan(let bookID):
                return try response(for: url,
                                    statusCode: 200,
                                    body: library.deleteLoan(forBookID: bookID))
            }
        } catch let error as LibraryStoreError {
            return try response(for: url,
                                error: error)
        }
    }

    private func response(for url: URL,
                          error: LibraryStoreError) throws -> (Data, HTTPURLResponse) {
        switch error {
        case .bookNotFound:
            return try response(for: url,
                                statusCode: 404)
        case .bookUnavailable:
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorResponse(error: "book_unavailable",
                                                    message: "This book is out on loan."))
        case .loanLimitReached:
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorResponse(error: "loan_limit_reached",
                                                    message: "You've reached your loan limit. Return a book to borrow another."))
        case .notBorrowed:
            return try response(for: url,
                                statusCode: 404,
                                body: ErrorResponse(error: "not_borrowed",
                                                    message: "You don't have this book on loan."))
        }
    }

    private func response(for url: URL,
                          statusCode: Int,
                          body: some Encodable) throws -> (Data, HTTPURLResponse) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        return try response(for: url,
                            statusCode: statusCode,
                            data: encoder.encode(body))
    }

    private func response(for url: URL,
                          statusCode: Int,
                          data: Data = Data()) throws -> (Data, HTTPURLResponse) {
        guard let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": "application/json"]) else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}
