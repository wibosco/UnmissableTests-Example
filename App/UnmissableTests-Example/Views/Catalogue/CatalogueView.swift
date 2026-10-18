//
//  CatalogueView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct CatalogueView: View {
    @Bindable var viewModel: CatalogueViewModel

    // MARK: - Views

    var body: some View {
        NavigationStack {
            List(viewModel.state.rows) { row in
                ListingRow(row: row)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeAction(for: row)
                    }
            }
            .overlay {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .failed:
                    ContentUnavailableView("Unable to Load Books",
                                           systemImage: "exclamationmark.triangle")
                case .loaded(let rows) where rows.isEmpty:
                    ContentUnavailableView("No Books",
                                           systemImage: "books.vertical")
                case .loaded:
                    EmptyView()
                }
            }
            .navigationTitle("Catalogue")
            .task {
                await viewModel.load()
            }
            .alert(viewModel.alert?.title ?? "",
                   isPresented: $viewModel.isShowingAlert,
                   presenting: viewModel.alert) { _ in
                Button("OK", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
        }
    }

    @ViewBuilder
    private func swipeAction(for row: CatalogueViewModel.Row) -> some View {
        switch row.action {
        case .borrow:
            Button("Borrow", systemImage: "book") {
                Task {
                    await viewModel.borrowBook(row)
                }
            }
            .tint(.green)
        case .return:
            Button("Return", systemImage: "arrow.uturn.backward") {
                Task {
                    await viewModel.returnBook(row)
                }
            }
            .tint(.orange)
        case nil:
            EmptyView()
        }
    }
}

private struct ListingRow: View {
    let row: CatalogueViewModel.Row

    // MARK: - Views

    var body: some View {
        HStack(spacing: 12) {
            Image(row.coverImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 60)
                .clipShape(.rect(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.headline)
                Text(row.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                availability
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var availability: some View {
        switch row.availability {
        case .available:
            Text("Available")
                .foregroundStyle(.green)
        case .onLoan:
            Text("On loan")
                .foregroundStyle(.orange)
        case .onLoanToYou:
            Text("On loan to you")
                .foregroundStyle(.purple)
        }
    }
}

private extension CatalogueViewModel.Alert {
    var title: String {
        switch self {
        case .loanLimitReached:
            "Loan Limit Reached"
        case .borrowFailed:
            "Unable to Borrow"
        case .returnFailed:
            "Unable to Return"
        }
    }

    var message: String {
        switch self {
        case .loanLimitReached:
            "Return a book before borrowing another."
        case .borrowFailed, .returnFailed:
            "Please try again."
        }
    }
}

#Preview {
    CatalogueView(viewModel: AppDependencies().catalogueViewModel)
}
