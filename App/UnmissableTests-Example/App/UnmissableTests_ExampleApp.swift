//
//  UnmissableTests_ExampleApp.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import SwiftUI

@main
struct UnmissableTests_ExampleApp: App {
    @State private var dependencies = AppDependencies()

    // MARK: - Views

    var body: some Scene {
        WindowGroup {
            ContentView(catalogueViewModel: dependencies.catalogueViewModel,
                        loansViewModel: dependencies.loansViewModel)
        }
    }
}
