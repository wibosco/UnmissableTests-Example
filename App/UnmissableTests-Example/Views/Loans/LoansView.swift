//
//  LoansView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import MockServer
import SwiftUI

struct LoansView: View {
    @Bindable var viewModel: LoansViewModel
    
    // MARK: - Views
    
    var body: some View {
        NavigationStack {
            List(rows) { row in
                LoanRow(row: row)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Return", systemImage: "arrow.uturn.backward") {
                            Task {
                                await viewModel.returnBook(row)
                            }
                        }
                        .tint(.orange)
                    }
            }
            .overlay {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .failed:
                    ContentUnavailableView("Unable to Load Loans",
                                           systemImage: "exclamationmark.triangle")
                case .loaded(let rows) where rows.isEmpty:
                    ContentUnavailableView("No Loans",
                                           systemImage: "book")
                case .loaded:
                    EmptyView()
                }
            }
            .navigationTitle("Loans")
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

    private var rows: [LoansViewModel.Row] {
        guard case .loaded(let rows) = viewModel.state else {
            return []
        }

        return rows
    }

    // MARK: - Alert

    private func title(for alert: LoansViewModel.Alert) -> String {
        switch alert {
        case .returnFailed:
            "Unable to Return"
        }
    }

    private func message(for alert: LoansViewModel.Alert) -> String {
        switch alert {
        case .returnFailed:
            "Please try again."
        }
    }
}

private struct LoanRow: View {
    let row: LoansViewModel.Row
    
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
                dueDate
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var dueDate: some View {
        if row.isOverdue {
            Text("Overdue - was due \(row.dueDate, format: .dateTime.day().month().year())")
                .foregroundStyle(.red)
        } else {
            Text("Due \(row.dueDate, format: .dateTime.day().month().year())")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let session = DefaultMockServer.session()
    let networkService = DefaultNetworkService(session: session)
    let repository = DefaultCatalogueRepository(baseURL: URL(string: "https://library.example.com")!,
                                                networkService: networkService)

    LoansView(viewModel: LoansViewModel(loanService: DefaultLoanService(repository: repository,
                                                                 now: Date.init)))
}
