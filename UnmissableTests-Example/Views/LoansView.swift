//
//  LoansView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct LoansView: View {
    let loanService: LoanService

    var body: some View {
        BookListView(title: "Borrowed",
                     loadItems: loanService.loans,
                     book: \.book,
                     actions: { [.return($0.book, using: loanService)] }) { loan in
            if loanService.isOverdue(loan) {
                Text("Overdue - was due \(loan.dueDate, format: .dateTime.day().month().year())")
                    .foregroundStyle(.red)
            } else {
                Text("Due \(loan.dueDate, format: .dateTime.day().month().year())")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LoansView(loanService: LoanService(repository: DefaultCatalogueRepository(bundle: .main),
                                       loanLimit: 5,
                                       loanPeriodInDays: 21,
                                       calendar: .current,
                                       now: Date.init))
}
