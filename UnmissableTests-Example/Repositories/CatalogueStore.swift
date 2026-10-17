//
//  CatalogueStore.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum CatalogueStoreError: Error, Equatable {
    case missingResource
    case unknownBook
    case alreadyBorrowed
    case loanLimitReached
    case bookUnavailable
    case invalidLoanPeriod
    case notBorrowed
}

/// Standin for actual network requests
@MainActor
final class CatalogueStore {
    private struct State {
        var listings: [Listing]
        var loans: [Loan]
    }

    private let bundle: Bundle
    private let decoder: JSONDecoder
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
    }

    // MARK: - Listings

    func listings() throws -> [Listing] {
        try loadedState().listings
    }

    // MARK: - Loans

    func loans() throws -> [Loan] {
        try loadedState().loans
    }

    func checkOut(bookID: String) throws {
        var state = try loadedState()

        guard let listing = state.listings.first(where: { $0.book.id == bookID }) else {
            throw CatalogueStoreError.unknownBook
        }

        guard listing.availability != .onLoanToYou else {
            throw CatalogueStoreError.alreadyBorrowed
        }

        guard state.loans.count < loanLimit else {
            throw CatalogueStoreError.loanLimitReached
        }

        guard listing.availability == .available else {
            throw CatalogueStoreError.bookUnavailable
        }

        let borrowedAt = now()

        guard let dueDate = calendar.date(byAdding: .day,
                                          value: loanPeriodInDays,
                                          to: borrowedAt) else {
            throw CatalogueStoreError.invalidLoanPeriod
        }

        try setAvailability(.onLoanToYou,
                            forBookWithID: bookID,
                            in: &state)
        state.loans.append(Loan(book: listing.book,
                                dueDate: dueDate))

        self.state = state
    }

    func checkIn(bookID: String) throws {
        var state = try loadedState()

        guard state.loans.contains(where: { $0.book.id == bookID }) else {
            throw CatalogueStoreError.notBorrowed
        }

        try setAvailability(.available,
                            forBookWithID: bookID,
                            in: &state)
        state.loans.removeAll { $0.book.id == bookID }

        self.state = state
    }
}

private extension CatalogueStore {
    // MARK: - State

    private func loadedState() throws -> State {
        if let state {
            return state
        }

        let bookDTOs: [BookDTO] = try load("books")
        let loanDTOs: [LoanDTO] = try load("loans")

        let listings = bookDTOs.map(\.listing)
        let books = listings.map(\.book)

        let loans = try loanDTOs.map { response in
            Loan(book: try book(withID: response.bookId,
                                in: books),
                 dueDate: response.dueDate)
        }

        let state = State(listings: listings,
                          loans: loans)
        self.state = state

        return state
    }

    private func setAvailability(_ availability: Availability,
                                 forBookWithID bookID: String,
                                 in state: inout State) throws {
        guard let index = state.listings.firstIndex(where: { $0.book.id == bookID }) else {
            throw CatalogueStoreError.unknownBook
        }

        state.listings[index] = Listing(book: state.listings[index].book,
                                        availability: availability)
    }

    private func book(withID bookID: String,
                      in books: [Book]) throws -> Book {
        guard let book = books.first(where: { $0.id == bookID }) else {
            throw CatalogueStoreError.unknownBook
        }

        return book
    }

    // MARK: - Loading

    private func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = bundle.url(forResource: name,
                                   withExtension: "json") else {
            throw CatalogueStoreError.missingResource
        }

        let data = try Data(contentsOf: url)

        return try decoder.decode(T.self,
                                  from: data)
    }
}
