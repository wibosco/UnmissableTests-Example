//
//  ListingsView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import MockServer
import SwiftUI

struct ListingsView: View {
    @Bindable var viewModel: ListingsViewModel
    
    // MARK: - Views
    
    var body: some View {
        NavigationStack {
            List(rows) { row in
                CatalogueRow(row: row)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if let action = row.action {
                            switch action {
                            case .borrow:
                                Button("Borrow", systemImage: "book") {
                                    Task {
                                        await viewModel.borrow(row)
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
                            }
                        }
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
            .alert(viewModel.alert.map(title(for:)) ?? "",
                   isPresented: $viewModel.isShowingAlert,
                   presenting: viewModel.alert) { _ in
                Button("OK", role: .cancel) {}
            } message: { alert in
                Text(message(for: alert))
            }
        }
    }

    private var rows: [ListingsViewModel.Row] {
        guard case .loaded(let rows) = viewModel.state else {
            return []
        }

        return rows
    }

    // MARK: - Alert

    private func title(for alert: ListingsViewModel.Alert) -> String {
        switch alert {
        case .loanLimitReached:
            "Loan Limit Reached"
        case .borrowFailed:
            "Unable to Borrow"
        case .returnFailed:
            "Unable to Return"
        }
    }

    private func message(for alert: ListingsViewModel.Alert) -> String {
        switch alert {
        case .loanLimitReached:
            "Return a book before borrowing another."
        case .borrowFailed, .returnFailed:
            "Please try again."
        }
    }
}

private struct CatalogueRow: View {
    let row: ListingsViewModel.Row
    
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

#Preview {
    let session = DefaultMockServer.session()
    let networkService = DefaultNetworkService(session: session)
    let repository = DefaultCatalogueRepository(baseURL: URL(string: "https://library.example.com")!,
                                                networkService: networkService)

    ListingsView(viewModel: ListingsViewModel(listingService: ListingService(repository: repository),
                                                loanService: LoanService(repository: repository,
                                                                         now: Date.init)))
}
