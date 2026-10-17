//
//  InMemoryServer.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

/// Standin for actual network requests
@MainActor
final class InMemoryServer: NetworkService {
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
    private let now: () -> Date

    // Changes are held in memory to stand in for the server, so they're lost when the app restarts.
    private var state: State?

    // MARK: - Init

    init(bundle: Bundle,
         loanLimit: Int,
         loanPeriodInDays: Int,
         calendar: Calendar,
         now: @escaping () -> Date) {
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

    // MARK: - NetworkService

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let route = Route(request: request) else {
            throw URLError(.badURL)
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
}

private extension InMemoryServer {
    // MARK: - Loans

    private func loanDTOs() throws -> [LoanDTO] {
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

    private func checkOut(bookID: String,
                          url: URL) throws -> (Data, HTTPURLResponse) {
        var state = try loadedState()

        guard let index = state.books.firstIndex(where: { $0.id == bookID }) else {
            return try response(for: url,
                                statusCode: 404)
        }

        guard state.books[index].availability != .onLoanToYou else {
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorDTO(error: .alreadyBorrowed))
        }

        guard state.loans.count < loanLimit else {
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorDTO(error: .loanLimitReached))
        }

        guard state.books[index].availability == .available else {
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorDTO(error: .bookUnavailable))
        }

        let borrowedAt = now()

        guard let dueDate = calendar.date(byAdding: .day,
                                          value: loanPeriodInDays,
                                          to: borrowedAt) else {
            return try response(for: url,
                                statusCode: 500)
        }

        state.books[index] = state.books[index].with(availability: .onLoanToYou)
        state.loans.append(LoanRecord(bookID: bookID,
                                      borrowedAt: borrowedAt,
                                      dueDate: dueDate))
        self.state = state

        return try response(for: url,
                            statusCode: 204)
    }

    private func checkIn(bookID: String,
                         url: URL) throws -> (Data, HTTPURLResponse) {
        var state = try loadedState()

        guard let index = state.books.firstIndex(where: { $0.id == bookID }) else {
            return try response(for: url,
                                statusCode: 404)
        }

        guard state.loans.contains(where: { $0.bookID == bookID }) else {
            return try response(for: url,
                                statusCode: 409,
                                body: ErrorDTO(error: .notBorrowed))
        }

        state.books[index] = state.books[index].with(availability: .available)
        state.loans.removeAll { $0.bookID == bookID }
        self.state = state

        return try response(for: url,
                            statusCode: 204)
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

    private func loadedState() throws -> State {
        if let state {
            return state
        }

        let books: [BookDTO] = try load("books")
        let loans: [LoanDTO] = try load("loans")

        let state = State(books: books,
                          loans: loans.map { LoanRecord(bookID: $0.book.id,
                                                        borrowedAt: $0.borrowedAt,
                                                        dueDate: $0.dueDate) })
        self.state = state

        return state
    }

    private func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = bundle.url(forResource: name,
                                   withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        let data = try Data(contentsOf: url)

        return try decoder.decode(T.self,
                                  from: data)
    }
}

private extension BookDTO {
    func with(availability: Status) -> BookDTO {
        BookDTO(id: id,
                title: title,
                author: author,
                isbn: isbn,
                coverImageName: coverImageName,
                availability: availability)
    }
}
