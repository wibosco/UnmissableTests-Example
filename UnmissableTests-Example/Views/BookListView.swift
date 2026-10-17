//
//  BookListView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct BookListView<Item, Detail: View>: View {
    private enum LoadState {
        case loading
        case loaded([Item])
        case failed
    }

    private let title: String
    private let loadItems: () async throws -> [Item]
    private let bookKeyPath: KeyPath<Item, Book>
    private let actions: (Item) -> [BookAction]
    private let detail: (Item) -> Detail

    @State private var state = LoadState.loading
    @State private var actionError: (any Error)?

    init(title: String,
         loadItems: @escaping () async throws -> [Item],
         book bookKeyPath: KeyPath<Item, Book>,
         actions: @escaping (Item) -> [BookAction],
         @ViewBuilder detail: @escaping (Item) -> Detail) {
        self.title = title
        self.loadItems = loadItems
        self.bookKeyPath = bookKeyPath
        self.actions = actions
        self.detail = detail
    }

    var body: some View {
        NavigationStack {
            List(sortedItems, id: bookKeyPath.appending(path: \Book.id)) { item in
                let book = item[keyPath: bookKeyPath]

                HStack(spacing: 12) {
                    Image(book.coverImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 60)
                        .clipShape(.rect(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.headline)
                        Text(book.author.fullName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        detail(item)
                            .font(.caption)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    ForEach(actions(item)) { action in
                        Button(action.title, systemImage: action.systemImage) {
                            Task {
                                await perform(action)
                            }
                        }
                        .tint(action.tint)
                    }
                }
            }
            .overlay {
                switch state {
                case .loading:
                    ProgressView()
                case .failed:
                    ContentUnavailableView("Unable to Load Books",
                                           systemImage: "exclamationmark.triangle")
                case .loaded(let items) where items.isEmpty:
                    ContentUnavailableView("No Books",
                                           systemImage: "books.vertical")
                case .loaded:
                    EmptyView()
                }
            }
            .navigationTitle(title)
            .task {
                await load()
            }
            .alert("Something Went Wrong",
                   isPresented: isShowingActionError,
                   presenting: actionError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Loading

    private func load() async {
        do {
            state = .loaded(try await loadItems())
        } catch {
            state = .failed
        }
    }

    private var sortedItems: [Item] {
        guard case .loaded(let items) = state else {
            return []
        }

        return items.sorted { lhs, rhs in
            let lhsBook = lhs[keyPath: bookKeyPath]
            let rhsBook = rhs[keyPath: bookKeyPath]

            let comparisons = [
                lhsBook.author.lastName.localizedStandardCompare(rhsBook.author.lastName),
                lhsBook.author.firstName.localizedStandardCompare(rhsBook.author.firstName),
                lhsBook.title.localizedStandardCompare(rhsBook.title)
            ]

            return comparisons.first { $0 != .orderedSame } == .orderedAscending
        }
    }

    // MARK: - Actions

    private func perform(_ action: BookAction) async {
        do {
            try await action.perform()
            await load()
        } catch {
            actionError = error
        }
    }

    private var isShowingActionError: Binding<Bool> {
        Binding {
            actionError != nil
        } set: { isShowing in
            if !isShowing {
                actionError = nil
            }
        }
    }
}
