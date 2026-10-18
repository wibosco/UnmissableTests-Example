//
//  MockServer.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Synchronization

/// Standin for actual network requests
nonisolated final class MockServer: URLProtocol {
    private struct Backend {
        private enum Route {
            case books
            case loans
            case checkOut(bookID: String)
            case checkIn(bookID: String)

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
                case "POST" where path.count == 3 && path[0] == "books" && path[2] == "checkout":
                    self = .checkOut(bookID: path[1])
                case "POST" where path.count == 3 && path[0] == "books" && path[2] == "checkin":
                    self = .checkIn(bookID: path[1])
                default:
                    return nil
                }
            }
        }

        private struct LoanRecord {
            let bookID: String
            let borrowedAt: Date
            let dueDate: Date
        }

        private struct State {
            var books: [BookDTO]
            var loans: [LoanRecord]
        }

        private let bundle: Bundle
        private let decoder: JSONDecoder
        private let encoder: JSONEncoder
        private let loanLimit: Int
        private let loanPeriodInDays: Int
        private let calendar: Calendar
        private let now: @Sendable () -> Date

        private var state: State?

        // MARK: - Init

        init(bundle: Bundle,
             loanLimit: Int,
             loanPeriodInDays: Int,
             calendar: Calendar,
             now: @escaping @Sendable () -> Date) {
            self.bundle = bundle
            self.loanLimit = loanLimit
            self.loanPeriodInDays = loanPeriodInDays
            self.calendar = calendar
            self.now = now

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            self.decoder = decoder

            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            self.encoder = encoder
        }

        // MARK: - Routing

        mutating func respond(to request: URLRequest) throws -> (Data, HTTPURLResponse) {
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            guard let route = Route(request: request) else {
                return try response(for: url,
                                    statusCode: 404)
            }

            do {
                switch route {
                case .books:
                    return try response(for: url,
                                        statusCode: 200,
                                        body: try loadedState().books)
                case .loans:
                    return try response(for: url,
                                        statusCode: 200,
                                        body: try loanDTOs())
                case .checkOut(let bookID):
                    return try checkOut(bookID: bookID,
                                        url: url)
                case .checkIn(let bookID):
                    return try checkIn(bookID: bookID,
                                       url: url)
                }
            } catch {
                return try response(for: url,
                                    statusCode: 500)
            }
        }

        // MARK: - Loans

        private mutating func loanDTOs() throws -> [LoanDTO] {
            let state = try loadedState()

            return state.loans.compactMap { record in
                guard let book = state.books.first(where: { $0.id == record.bookID }) else {
                    return nil
                }

                return LoanDTO(book: book,
                               borrowedAt: record.borrowedAt,
                               dueDate: record.dueDate)
            }
        }

        private mutating func checkOut(bookID: String,
                                       url: URL) throws -> (Data, HTTPURLResponse) {
            var state = try loadedState()

            guard let index = state.books.firstIndex(where: { $0.id == bookID }) else {
                return try response(for: url,
                                    statusCode: 404)
            }

            guard state.books[index].availability != .onLoanToYou else {
                return try response(for: url,
                                    statusCode: 409,
                                    data: try jsonData(named: "check-out-failure-already-borrowed"))
            }

            guard state.loans.count < loanLimit else {
                return try response(for: url,
                                    statusCode: 409,
                                    data: try jsonData(named: "check-out-failure-loan-limit-reached"))
            }

            guard state.books[index].availability == .available else {
                return try response(for: url,
                                    statusCode: 409,
                                    data: try jsonData(named: "check-out-failure-book-unavailable"))
            }

            let borrowedAt = now()

            guard let dueDate = calendar.date(byAdding: .day,
                                              value: loanPeriodInDays,
                                              to: borrowedAt) else {
                return try response(for: url,
                                    statusCode: 500)
            }

            state.books[index] = bookDTO(state.books[index],
                                         withAvailability: .onLoanToYou)
            state.loans.append(LoanRecord(bookID: bookID,
                                          borrowedAt: borrowedAt,
                                          dueDate: dueDate))
            self.state = state

            return try response(for: url,
                                statusCode: 204)
        }

        private mutating func checkIn(bookID: String,
                                      url: URL) throws -> (Data, HTTPURLResponse) {
            var state = try loadedState()

            guard let index = state.books.firstIndex(where: { $0.id == bookID }) else {
                return try response(for: url,
                                    statusCode: 404)
            }

            guard state.loans.contains(where: { $0.bookID == bookID }) else {
                return try response(for: url,
                                    statusCode: 409,
                                    data: try jsonData(named: "check-in-failure-not-borrowed"))
            }

            state.books[index] = bookDTO(state.books[index],
                                         withAvailability: .available)
            state.loans.removeAll { $0.bookID == bookID }
            self.state = state

            return try response(for: url,
                                statusCode: 204)
        }

        private func bookDTO(_ bookDTO: BookDTO,
                             withAvailability availability: BookDTO.Status) -> BookDTO {
            BookDTO(id: bookDTO.id,
                    title: bookDTO.title,
                    author: bookDTO.author,
                    isbn: bookDTO.isbn,
                    coverImageName: bookDTO.coverImageName,
                    availability: availability)
        }

        // MARK: - Responses

        private func response(for url: URL,
                              statusCode: Int,
                              body: some Encodable) throws -> (Data, HTTPURLResponse) {
            try response(for: url,
                         statusCode: statusCode,
                         data: try encoder.encode(body))
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

        // MARK: - State

        private mutating func loadedState() throws -> State {
            if let state {
                return state
            }

            let books: [BookDTO] = try load("books-success")
            let loans: [LoanDTO] = try load("loans-success")

            let state = State(books: books,
                              loans: loans.map { LoanRecord(bookID: $0.book.id,
                                                            borrowedAt: $0.borrowedAt,
                                                            dueDate: $0.dueDate) })
            self.state = state

            return state
        }

        private func load<T: Decodable>(_ name: String) throws -> T {
            try decoder.decode(T.self,
                               from: try jsonData(named: name))
        }

        private func jsonData(named name: String) throws -> Data {
            guard let url = bundle.url(forResource: name,
                                       withExtension: "json") else {
                throw URLError(.fileDoesNotExist)
            }

            return try Data(contentsOf: url)
        }
    }

    // URLSession creates a new MockServer for every request, so the backend has to be shared between them. Changes
    // are held in memory to stand in for the server, so they're lost when the app restarts.
    private static let backend = Mutex<Backend?>(nil)

    // MARK: - Configuration

    static func session(bundle: Bundle,
                        loanLimit: Int,
                        loanPeriodInDays: Int,
                        calendar: Calendar,
                        now: @escaping @Sendable () -> Date) -> URLSession {
        backend.withLock { backend in
            backend = Backend(bundle: bundle,
                              loanLimit: loanLimit,
                              loanPeriodInDays: loanPeriodInDays,
                              calendar: calendar,
                              now: now)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockServer.self]

        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let request = self.request

        do {
            let (data, response) = try Self.backend.withLock { backend in
                guard let response = try backend?.respond(to: request) else {
                    throw URLError(.cannotConnectToHost)
                }

                return response
            }

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

    override func stopLoading() {}
}
