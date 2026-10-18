//
//  HTTPURLResponse+TestData.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

extension HTTPURLResponse {
    static func testData(url: URL = URL(string: "https://test.example.com")!,
                         statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil)!
    }
}
