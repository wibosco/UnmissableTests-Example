//
//  LoansView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct LoansView: View {
    @Bindable var viewModel: LoansViewModel

    // MARK: - Views

    var body: some View {
        NavigationStack {
            List(viewModel.state.rows) { row in
                LoanRow(row: row)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeAction(for: row)
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
            .alert(viewModel.alert?.title ?? "",
                   isPresented: $viewModel.isShowingAlert,
                   presenting: viewModel.alert) { _ in
                Button("OK", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
        }
    }

    private func swipeAction(for row: LoansViewModel.Row) -> some View {
        Button("Return", systemImage: "arrow.uturn.backward") {
            Task {
                await viewModel.returnBook(row)
            }
        }
        .tint(.orange)
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

private extension LoansViewModel.Alert {
    var title: String {
        switch self {
        case .returnFailed:
            "Unable to Return"
        }
    }

    var message: String {
        switch self {
        case .returnFailed:
            "Please try again."
        }
    }
}

#Preview {
    LoansView(viewModel: AppDependencies().loansViewModel)
}
