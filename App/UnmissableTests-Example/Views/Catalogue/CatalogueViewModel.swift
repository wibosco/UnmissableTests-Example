//
//  CatalogueViewModel.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Observation

@Observable
final class CatalogueViewModel {
    struct Row: Identifiable, Equatable {
        enum Availability: Equatable {
            case available
            case onLoan
            case onLoanToYou
        }

        enum Action: Equatable {
            case borrow
            case `return`
        }

        let id: String
        let title: String
        let authorName: String
        let coverImageName: String
        let availability: Availability

        var action: Action? {
            switch availability {
            case .available:
                .borrow
            case .onLoan:
                nil
            case .onLoanToYou:
                .return
            }
        }
    }

    enum State: Equatable {
        case loading
        case loaded([Row])
        case failed

        var rows: [Row] {
            guard case .loaded(let rows) = self else {
                return []
            }

            return rows
        }
    }

    enum Alert: Equatable {
        case loanLimitReached
        case borrowFailed
        case returnFailed
    }

    private(set) var state = State.loading
    private(set) var alert: Alert?

    private let listingService: ListingService
    private let loanService: LoanService
    
    @ObservationIgnored private var listings = [Listing]()

    var isShowingAlert: Bool {
        get {
            alert != nil
        }
        set {
            if !newValue {
                alert = nil
            }
        }
    }
    
    // MARK: - Init

    init(listingService: ListingService,
         loanService: LoanService) {
        self.listingService = listingService
        self.loanService = loanService
    }

    // MARK: - Loading

    func load() async {
        do {
            listings = try await listingService.listings()
        } catch {
            state = .failed
            return
        }

        await refreshLoans()
    }

    private func refreshLoans() async {
        do {
            let loanedBookIDs = Set(try await loanService.loans().map(\.book.id))

            state = .loaded(listings
                .sorted(using: [
                    SortDescriptor(\Listing.book.author.lastName),
                    SortDescriptor(\Listing.book.author.firstName),
                    SortDescriptor(\Listing.book.title)
                ])
                .map { row(for: $0,
                           loanedBookIDs: loanedBookIDs) })
        } catch {
            state = .failed
        }
    }

    private func row(for listing: Listing,
                     loanedBookIDs: Set<String>) -> Row {
        Row(id: listing.book.id,
            title: listing.book.title,
            authorName: listing.book.author.lastNameFirst,
            coverImageName: listing.book.coverImageName,
            availability: availability(for: listing,
                                       loanedBookIDs: loanedBookIDs))
    }

    private func availability(for listing: Listing,
                              loanedBookIDs: Set<String>) -> Row.Availability {
        // The loan cache, rather than the catalogue, is the source of truth for the user's own loans.
        if loanedBookIDs.contains(listing.book.id) {
            return .onLoanToYou
        }

        switch listing.availability {
        case .available, .onLoanToYou:
            return .available
        case .onLoan:
            return .onLoan
        }
    }

    // MARK: - Borrowing

    func borrowBook(_ row: Row) async {
        guard let book = loadedBook(for: row) else {
            return
        }

        do {
            try await loanService.borrowBook(book)
            await refreshLoans()
        } catch {
            switch error {
            case .loanLimitReached:
                alert = .loanLimitReached
            case .failed:
                alert = .borrowFailed
            }
        }
    }

    // MARK: - Returning

    func returnBook(_ row: Row) async {
        guard let book = loadedBook(for: row) else {
            return
        }

        do {
            try await loanService.returnBook(book)
            await refreshLoans()
        } catch {
            alert = .returnFailed
        }
    }

    private func loadedBook(for row: Row) -> Book? {
        listings.first(where: { $0.book.id == row.id })?.book
    }
}

private extension Author {
    var lastNameFirst: String {
        "\(lastName), \(firstName)"
    }
}
