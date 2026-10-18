//
//  MockServer.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

/// Standin for actual network requests
public final class DefaultMockServer: URLProtocol {
    private enum Route {
        case books
        case loans
        case checkOut
        case checkIn

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
            case "POST" where path.count == 3 && path[0] == "books" && path[2] == "checkout":
                self = .checkOut
            case "POST" where path.count == 3 && path[0] == "books" && path[2] == "checkin":
                self = .checkIn
            default:
                return nil
            }
        }
    }

    // MARK: - Session

    public static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DefaultMockServer.self]

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
                                data: try jsonData(named: "books-success"))
        case .loans:
            return try response(for: url,
                                statusCode: 200,
                                data: try jsonData(named: "loans-success"))
        case .checkOut:
            return try response(for: url,
                                statusCode: 200,
                                data: try jsonData(named: "check-out-success"))
        case .checkIn:
            return try response(for: url,
                                statusCode: 200,
                                data: try jsonData(named: "check-in-success"))
        }
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
        guard let url = Bundle(for: DefaultMockServer.self).url(forResource: name,
                                                                withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        return try Data(contentsOf: url)
    }
}
