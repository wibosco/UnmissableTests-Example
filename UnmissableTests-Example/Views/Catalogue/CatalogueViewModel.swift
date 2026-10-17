//
//  CatalogueViewModel.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Observation

@MainActor
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

    private let catalogueService: CatalogueService
    private let loanService: LoanService
    @ObservationIgnored private var books = [String: Book]()

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

    init(catalogueService: CatalogueService,
         loanService: LoanService) {
        self.catalogueService = catalogueService
        self.loanService = loanService
    }

    // MARK: - Loading

    func load() async {
        do {
            let listings = try await catalogueService.catalogue()

            books = Dictionary(uniqueKeysWithValues: listings.map { ($0.book.id, $0.book) })
            state = .loaded(listings
                .sorted(using: [
                    SortDescriptor(\Listing.book.author.lastName),
                    SortDescriptor(\Listing.book.author.firstName),
                    SortDescriptor(\Listing.book.title)
                ])
                .map { row(for: $0) })
        } catch {
            state = .failed
        }
    }

    private func row(for listing: Listing) -> Row {
        let availability: Row.Availability
        let action: Row.Action?

        switch listing.availability {
        case .available:
            availability = .available
            action = .borrow
        case .onLoan:
            availability = .onLoan
            action = nil
        case .onLoanToYou:
            availability = .onLoanToYou
            action = .return
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
        guard let book = books[row.id] else {
            return
        }

        do {
            try await loanService.borrow(book)
            await load()
        } catch LoanError.loanLimitReached {
            alert = .loanLimitReached
        } catch {
            alert = .borrowFailed
        }
    }

    func returnBook(_ row: Row) async {
        guard let book = books[row.id] else {
            return
        }

        do {
            try await loanService.returnBook(book)
            await load()
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
