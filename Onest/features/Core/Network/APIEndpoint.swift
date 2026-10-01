//
//  APIEndpoint.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public enum APIEndpoint {
    case login(LoginRequest)
    case refresh(TokenRefreshRequest)
    case getLoans
    case getLoanDetail(id: String)
    case quote(LoanQuoteRequest)
    case createLoan(request: CreateLoanRequest, idempotencyKey: String)

    public var baseURL: URL {
        return URL(string: "https://api.onest.com")!
    }

    public var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .refresh:
            return "/auth/refresh"
        case .getLoans:
            return "/loans"
        case .getLoanDetail(let id):
            return "/loans/\(id)"
        case .quote:
            return "/loans/quote"
        case .createLoan:
            return "/loans"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .login, .refresh, .quote, .createLoan:
            return .post
        case .getLoans, .getLoanDetail:
            return .get
        }
    }

    public var requiresAuth: Bool {
        switch self {
        case .login, .refresh:
            return false
        case .getLoans, .getLoanDetail, .quote, .createLoan:
            return true
        }
    }

    public func buildRequest(accessToken: String? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        let dateFormatter = ISO8601DateFormatter()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(dateFormatter.string(from: date))
        }

        switch self {
        case .login(let req):
            request.httpBody = try encoder.encode(req)
        case .refresh(let req):
            request.httpBody = try encoder.encode(req)
        case .quote(let req):
            request.httpBody = try encoder.encode(req)
        case .createLoan(let req, let idempotencyKey):
            request.httpBody = try encoder.encode(req)
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        case .getLoans, .getLoanDetail:
            break
        }

        return request
    }
}
