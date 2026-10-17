//
//  ReservationsView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct ReservationsView: View {
    let reservationService: ReservationService

    var body: some View {
        BookListView(title: "Reserved",
                     loadItems: reservationService.reservations,
                     book: \.book) { reservation in
            Text("Reserved \(reservation.reservedAt, format: .dateTime.day().month().year())")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ReservationsView(reservationService: ReservationService(repository: DefaultCatalogueRepository(bundle: .main)))
}
