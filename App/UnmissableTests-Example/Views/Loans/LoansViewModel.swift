//
//  LoansViewModel.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Observation

@Observable
final class LoansViewModel {
    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let authorName: String
        let coverImageName: String
        let dueDate: Date
        let isOverdue: Bool
    }

    enum State: Equatable {
        case loading
        case loaded([Row])
        case failed
    }

    enum Alert: Equatable {
        case returnFailed
    }

    private(set) var state = State.loading
    private(set) var alert: Alert?

    private let loanService: LoanService
    @ObservationIgnored private var books = [String: Book]()

    private static let sortOrder: [SortDescriptor<Loan>] = [
        SortDescriptor(\Loan.dueDate),
        SortDescriptor(\Loan.book.author.lastName),
        SortDescriptor(\Loan.book.author.firstName),
        SortDescriptor(\Loan.book.title)
    ]

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

    init(loanService: LoanService) {
        self.loanService = loanService
    }

    // MARK: - Loading

    func load() async {
        do {
            let loans = try await loanService.loans()

            books = Dictionary(uniqueKeysWithValues: loans.map { ($0.book.id, $0.book) })
            state = .loaded(loans
                .sorted(using: Self.sortOrder)
                .map { row(for: $0) })
        } catch {
            state = .failed
        }
    }

    private func row(for loan: Loan) -> Row {
        Row(id: loan.book.id,
            title: loan.book.title,
            authorName: loan.book.author.fullName,
            coverImageName: loan.book.coverImageName,
            dueDate: loan.dueDate,
            isOverdue: loanService.isOverdue(loan))
    }

    // MARK: - Returning

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
