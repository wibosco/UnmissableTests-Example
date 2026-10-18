//
//  ListingsViewModel.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Observation

@Observable
final class ListingsViewModel {
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
        let action: Action?
    }

    enum State: Equatable {
        case loading
        case loaded([Row])
        case failed
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

        await updateState()
    }

    private func updateState() async {
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
        let availability: Row.Availability
        let action: Row.Action?

        // The loan cache, rather than the catalogue, is the source of truth for the user's own loans.
        if loanedBookIDs.contains(listing.book.id) {
            availability = .onLoanToYou
            action = .return
        } else {
            switch listing.availability {
            case .available, .onLoanToYou:
                availability = .available
                action = .borrow
            case .onLoan:
                availability = .onLoan
                action = nil
            }
        }

        return Row(id: listing.book.id,
                   title: listing.book.title,
                   authorName: listing.book.author.fullName,
                   coverImageName: listing.book.coverImageName,
                   availability: availability,
                   action: action)
    }

    // MARK: - Lending

    func borrow(_ row: Row) async {
        guard let book = listings.first(where: { $0.book.id == row.id })?.book else {
            return
        }

        do {
            try await loanService.borrowBook(book)
            await updateState()
        } catch LoanError.loanLimitReached {
            alert = .loanLimitReached
        } catch {
            alert = .borrowFailed
        }
    }

    func returnBook(_ row: Row) async {
        guard let book = listings.first(where: { $0.book.id == row.id })?.book else {
            return
        }

        do {
            try await loanService.returnBook(book)
            await updateState()
        } catch {
            alert = .returnFailed
        }
    }
}

private extension Author {
    var fullName: String {
        "\(lastName), \(firstName)"
    }
}
