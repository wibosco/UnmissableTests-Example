//
//  URLRequest+TestData.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

extension URLRequest {
    static func testData(url: URL = URL(string: "https://test.example.com")!) -> URLRequest {
        URLRequest(url: url)
    }
}
