//
//  ContentView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import SwiftUI

struct ContentView: View {
    let catalogueService: CatalogueService
    let loanService: LoanService
    let reservationService: ReservationService

    var body: some View {
        TabView {
            Tab("All Books", systemImage: "books.vertical") {
                CatalogueView(catalogueService: catalogueService)
            }

            Tab("Borrowed", systemImage: "book") {
                LoansView(loanService: loanService)
            }

            Tab("Reserved", systemImage: "bookmark") {
                ReservationsView(reservationService: reservationService)
            }
        }
    }
}

#Preview {
    let repository = DefaultCatalogueRepository(bundle: .main)

    ContentView(catalogueService: CatalogueService(repository: repository),
                loanService: LoanService(repository: repository,
                                         loanLimit: 5,
                                         loanPeriodInDays: 21,
                                         calendar: .current,
                                         now: Date.init),
                reservationService: ReservationService(repository: repository))
}
