//
//  MockLibraryServer.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

/// Stands in for the library API. Fixed data, such as the catalogue and existing loans, is
/// read from JSON files; responses that depend on the request are built from that data.
public final class MockLibraryServer: URLProtocol {
    private enum Route {
        case books
        case loans
        case createLoan(bookID: String)
        case deleteLoan(bookID: String)

        init?(request: URLRequest) {
            guard let url = request.url else {
                return nil
            }

            let path = Array(url.pathComponents.dropFirst())

            switch request.httpMethod ?? "GET" {
            case "GET" where path == ["books"]:
                self = .books
            case "GET" where path == ["loans"]:
                self = .loans
            case "PUT" where path.count == 2 && path[0] == "loans":
                self = .createLoan(bookID: path[1])
            case "DELETE" where path.count == 2 && path[0] == "loans":
                self = .deleteLoan(bookID: path[1])
            default:
                return nil
            }
        }
    }

    // MARK: - Session

    public static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLibraryServer.self]

        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol

    public override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    public override func startLoading() {
        do {
            let (data, response) = try cannedResponse(for: request)

            client?.urlProtocol(self,
                                didReceive: response,
                                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self,
                                didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self,
                                didFailWithError: error)
        }
    }

    public override func stopLoading() {}

    // MARK: - Responses

    private func cannedResponse(for request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        guard let route = Route(request: request) else {
            return try response(for: url,
                                statusCode: 404)
        }

        switch route {
        case .books:
            return try response(for: url,
                                statusCode: 200,
                                data: try jsonData(named: "get-books-success"))
        case .loans:
            return try response(for: url,
                                statusCode: 200,
                                data: try loansShiftedToNow())
        case .createLoan(let bookID):
            guard let book = try book(withID: bookID,
                                      availability: "on_loan_to_you") else {
                return try response(for: url,
                                    statusCode: 404)
            }

            let borrowedDate = Date()
            let loan: [String: Any] = [
                "book": book,
                "borrowed_date": ISO8601DateFormatter().string(from: borrowedDate),
                "due_date": ISO8601DateFormatter().string(from: borrowedDate.addingTimeInterval(loanPeriod))
            ]

            return try response(for: url,
                                statusCode: 200,
                                data: try JSONSerialization.data(withJSONObject: loan))
        case .deleteLoan(let bookID):
            guard let book = try book(withID: bookID,
                                      availability: "available") else {
                return try response(for: url,
                                    statusCode: 404)
            }

            return try response(for: url,
                                statusCode: 200,
                                data: try JSONSerialization.data(withJSONObject: book))
        }
    }

    private var loanPeriod: TimeInterval {
        21 * 24 * 60 * 60
    }

    private func book(withID id: String,
                      availability: String) throws -> [String: Any]? {
        guard let json = try JSONSerialization.jsonObject(with: jsonData(named: "get-books-success")) as? [String: Any],
              let books = json["books"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        guard var book = books.first(where: { $0["id"] as? String == id }) else {
            return nil
        }

        book["availability"] = availability

        return book
    }

    private func loansShiftedToNow() throws -> Data {
        let formatter = ISO8601DateFormatter()

        // The fixture's dates were written on this day. Shifting them by the time since keeps the same mix of
        // due and overdue loans whenever the app runs, rather than every loan eventually becoming overdue.
        guard let fixtureDate = formatter.date(from: "2026-10-18T00:00:00Z"),
              var json = try JSONSerialization.jsonObject(with: jsonData(named: "get-loans-success")) as? [String: Any],
              let loans = json["loans"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        let offset = Date().timeIntervalSince(fixtureDate)

        json["loans"] = try loans.map { loan in
            var loan = loan

            for key in ["borrowed_date", "due_date"] {
                guard let string = loan[key] as? String,
                      let date = formatter.date(from: string) else {
                    throw URLError(.cannotParseResponse)
                }

                loan[key] = formatter.string(from: date.addingTimeInterval(offset))
            }

            return loan
        }

        return try JSONSerialization.data(withJSONObject: json)
    }

    private func response(for url: URL,
                          statusCode: Int,
                          data: Data = Data()) throws -> (Data, HTTPURLResponse) {
        guard let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": "application/json"]) else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }

    private func jsonData(named name: String) throws -> Data {
        guard let url = Bundle(for: MockLibraryServer.self).url(forResource: name,
                                                                withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        return try Data(contentsOf: url)
    }
}
