//
//  LoanService.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public protocol LoanServiceProtocol: Sendable {
    func getLoans() async throws -> [Loan]
    func getLoanDetail(id: String) async throws -> Loan
    func getQuote(amount: Double, termMonths: Int) async throws -> LoanQuoteResponse
    func createLoan(amount: Double, termMonths: Int, idempotencyKey: String) async throws -> Loan
}

public final class LoanService: LoanServiceProtocol, @unchecked Sendable {
    public static let shared = LoanService()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getLoans() async throws -> [Loan] {
        let endpoint = APIEndpoint.getLoans
        return try await apiClient.request(endpoint)
    }

    public func getLoanDetail(id: String) async throws -> Loan {
        let endpoint = APIEndpoint.getLoanDetail(id: id)
        return try await apiClient.request(endpoint)
    }

    public func getQuote(amount: Double, termMonths: Int) async throws -> LoanQuoteResponse {
        let request = LoanQuoteRequest(amount: amount, termMonths: termMonths)
        let endpoint = APIEndpoint.quote(request)
        return try await apiClient.request(endpoint)
    }

    public func createLoan(amount: Double, termMonths: Int, idempotencyKey: String) async throws -> Loan {
        let request = CreateLoanRequest(amount: amount, termMonths: termMonths)
        let endpoint = APIEndpoint.createLoan(request: request, idempotencyKey: idempotencyKey)
        return try await apiClient.request(endpoint)
    }
}
