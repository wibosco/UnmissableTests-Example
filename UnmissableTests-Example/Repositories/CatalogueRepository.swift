//
//  CatalogueRepository.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum Availability: Equatable, Sendable {
    case available
    case onLoan
    case onLoanToYou
}

@MainActor
protocol CatalogueRepository {
    func catalogue() async throws -> [Listing]
    func loans() async throws -> [Loan]
    
    func checkOut(bookID: String) async throws
    func checkIn(bookID: String) async throws
}

enum CatalogueRepositoryError: Error, Equatable {
    case alreadyBorrowed
    case loanLimitReached
    case bookUnavailable
    case notBorrowed
}

@MainActor
final class DefaultCatalogueRepository: CatalogueRepository {
    private let store: CatalogueStore

    // MARK: - Init

    init(store: CatalogueStore) {
        self.store = store
    }

    // MARK: - Catalogue

    func catalogue() async throws -> [Listing] {
        try store.listings()
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        try store.loans()
    }

    func checkOut(bookID: String) async throws {
        do {
            try store.checkOut(bookID: bookID)
        } catch let error as CatalogueStoreError {
            throw repositoryError(for: error)
        }
    }

    func checkIn(bookID: String) async throws {
        do {
            try store.checkIn(bookID: bookID)
        } catch let error as CatalogueStoreError {
            throw repositoryError(for: error)
        }
    }

    private func repositoryError(for error: CatalogueStoreError) -> any Error {
        switch error {
        case .alreadyBorrowed:
            return CatalogueRepositoryError.alreadyBorrowed
        case .loanLimitReached:
            return CatalogueRepositoryError.loanLimitReached
        case .bookUnavailable:
            return CatalogueRepositoryError.bookUnavailable
        case .notBorrowed:
            return CatalogueRepositoryError.notBorrowed
        case .missingResource, .unknownBook, .invalidLoanPeriod:
            return error
        }
    }
}
