//
//  NetworkServiceTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct NetworkServiceTests {

    // MARK: - Send

    @Test("Given a request is sent, when it's made, then the session is asked to load that request")
    func sendRequest() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"message": "success"}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: 200)))

        let sut = createSUT(session: session)

        _ = try await sut.send(URLRequest.testData(url: URL(string: "https://library.example.com/books")!),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)

        #expect(session.events == [.data(for: URLRequest.testData(url: URL(string: "https://library.example.com/books")!))])
    }

    @Test("Given a request is sent, when the response is successful, then the decoded body is returned")
    func successfulSend() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"message": "success"}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: 200)))

        let sut = createSUT(session: session)

        let response = try await sut.send(URLRequest.testData(),
                                          success: SuccessDTO.self,
                                          failure: FailureDTO.self)

        #expect(response == SuccessDTO(message: "success"))
    }

    @Test("Given a request is sent, when the response body has snake case keys and ISO 8601 dates, then the body is decoded")
    func sendDecodesSnakeCaseKeysAndISO8601Dates() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"book_title": "Dracula", "due_date": "2026-10-18T09:00:00Z"}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: 200)))

        let sut = createSUT(session: session)

        let response = try await sut.send(URLRequest.testData(),
                                          success: LoanSummaryDTO.self,
                                          failure: FailureDTO.self)

        let expectedResponse = LoanSummaryDTO(bookTitle: "Dracula",
                                              dueDate: ISO8601DateFormatter().date(from: "2026-10-18T09:00:00Z")!)

        #expect(response == expectedResponse)
    }

    @Test("Given a request is sent, when the response's status code is at either end of the 2xx range, then the decoded body is returned",
          arguments: [
            200,
            299
          ] as [Int]
    )
    func sendWithAcceptableStatusCode(statusCode: Int) async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"message": "success"}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: statusCode)))

        let sut = createSUT(session: session)

        let response = try await sut.send(URLRequest.testData(),
                                          success: SuccessDTO.self,
                                          failure: FailureDTO.self)

        #expect(response == SuccessDTO(message: "success"))
    }

    @Test("Given a request is sent, when the response's status code is outside the 2xx range and its body can't be decoded, then an unacceptable status code error is thrown",
          arguments: [
            199,
            300,
            500
          ] as [Int]
    )
    func failedSendWithUnacceptableStatusCode(statusCode: Int) async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(),
                                         HTTPURLResponse.testData(statusCode: statusCode)))

        let sut = createSUT(session: session)

        await #expect(throws: NetworkServiceError<FailureDTO>.unacceptableStatusCode(statusCode)) {
            try await sut.send(URLRequest.testData(),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)
        }
    }

    @Test("Given a request is sent, when the response's status code is outside the 2xx range and its body is a failure, then a failure response error is thrown")
    func failedSendWithErrorResponse() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"error": "loan_limit_reached"}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: 409)))

        let sut = createSUT(session: session)

        await #expect(throws: NetworkServiceError<FailureDTO>.failureResponse(FailureDTO(error: "loan_limit_reached"))) {
            try await sut.send(URLRequest.testData(),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)
        }
    }

    @Test("Given a request is sent, when the session throws, then a request failed error is thrown")
    func failedSendWithSessionError() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .failure(URLError(.notConnectedToInternet))

        let sut = createSUT(session: session)

        await #expect(throws: NetworkServiceError<FailureDTO>.requestFailed) {
            try await sut.send(URLRequest.testData(),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)
        }
    }

    @Test("Given a request is sent, when the response isn't an HTTP response, then a request failed error is thrown")
    func failedSendWithNonHTTPResponse() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"message": "success"}"#.utf8),
                                         URLResponse(url: URL(string: "https://test.example.com")!,
                                                     mimeType: nil,
                                                     expectedContentLength: 0,
                                                     textEncodingName: nil)))

        let sut = createSUT(session: session)

        await #expect(throws: NetworkServiceError<FailureDTO>.requestFailed) {
            try await sut.send(URLRequest.testData(),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)
        }
    }

    @Test("Given a request is sent, when the response is successful but its body can't be decoded, then a decoding failed error is thrown")
    func failedSendWithUndecodableBody() async throws {
        let session = StubHTTPSession()
        session.dataResponse = .success((Data(#"{"unexpected": true}"#.utf8),
                                         HTTPURLResponse.testData(statusCode: 200)))

        let sut = createSUT(session: session)

        await #expect(throws: NetworkServiceError<FailureDTO>.decodingFailed) {
            try await sut.send(URLRequest.testData(),
                               success: SuccessDTO.self,
                               failure: FailureDTO.self)
        }
    }
}

extension NetworkServiceTests {
    func createSUT(session: HTTPSession = StubHTTPSession()) -> DefaultNetworkService {
        DefaultNetworkService(session: session)
    }
}

private nonisolated struct SuccessDTO: Decodable, Equatable, Sendable {
    let message: String
}

private nonisolated struct LoanSummaryDTO: Decodable, Equatable, Sendable {
    let bookTitle: String
    let dueDate: Date
}

private nonisolated struct FailureDTO: Decodable, Equatable, Sendable {
    let error: String
}
