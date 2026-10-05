//
//  TestMocks.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//
import Foundation

#if canImport(Onest)
@testable import Onest
#endif

public final class MockTokenStorage: TokenStorageProtocol, @unchecked Sendable {
    private var session: UserSession?
    private let lock = NSLock()

    public init(initialSession: UserSession? = nil) {
        self.session = initialSession
    }

    public func saveSession(_ session: UserSession) throws {
        lock.lock()
        defer { lock.unlock() }
        self.session = session
    }

    public func getSession() -> UserSession? {
        lock.lock()
        defer { lock.unlock() }
        return session
    }

    public func getAccessToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return session?.accessToken
    }

    public func getRefreshToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return session?.refreshToken
    }

    public func updateTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let current = session else {
            throw APIError.sessionExpired
        }
        self.session = UserSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            user: current.user
        )
    }

    public func clearSession() throws {
        lock.lock()
        defer { lock.unlock() }
        self.session = nil
    }
}

public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    public var shouldSucceed: Bool = true
    public var mockSession: UserSession?
    public var errorToThrow: APIError = .unauthorized(message: "Credenciales inválidas")
    public private(set) var loginCallCount: Int = 0
    public private(set) var logoutCallCount: Int = 0

    public init() {
        self.mockSession = UserSession(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresAt: Date().addingTimeInterval(60),
            user: User(id: "usr_1", name: "Ricardo Messon", email: "usuario@onest.com")
        )
    }

    public var isAuthenticated: Bool {
        return mockSession != nil
    }

    public func getCurrentSession() -> UserSession? {
        return mockSession
    }

    public func login(username: String, password: String) async throws -> UserSession {
        loginCallCount += 1
        if shouldSucceed, let session = mockSession {
            return session
        }
        throw errorToThrow
    }

    public func logout() throws {
        logoutCallCount += 1
        mockSession = nil
    }
}

public final class MockLoanService: LoanServiceProtocol, @unchecked Sendable {
    public var shouldSucceed: Bool = true
    public var mockLoans: [Loan] = []
    public var mockQuote: LoanQuoteResponse?
    public var errorToThrow: APIError = .serverError(message: "Error de servidor")
    public private(set) var createLoanKeysReceived: [String] = []

    public init() {}

    public func getLoans() async throws -> [Loan] {
        if shouldSucceed {
            return mockLoans
        }
        throw errorToThrow
    }

    public func getLoanDetail(id: String) async throws -> Loan {
        if shouldSucceed {
            if let loan = mockLoans.first(where: { $0.id == id }) {
                return loan
            }
            throw APIError.notFound(message: "No encontrado")
        }
        throw errorToThrow
    }

    public func getQuote(amount: Double, termMonths: Int) async throws -> LoanQuoteResponse {
        if shouldSucceed {
            if let quote = mockQuote {
                return quote
            }
            let annualRate = 0.18
            let monthly = (amount / Double(termMonths)) * 1.09
            let total = monthly * Double(termMonths)
            return LoanQuoteResponse(
                amount: amount,
                termMonths: termMonths,
                annualRate: annualRate,
                monthlyPayment: monthly,
                totalCost: total,
                totalInterest: total - amount
            )
        }
        throw errorToThrow
    }

    public func createLoan(amount: Double, termMonths: Int, idempotencyKey: String) async throws -> Loan {
        createLoanKeysReceived.append(idempotencyKey)
        if shouldSucceed {
            return Loan(
                id: "LOAN-\(createLoanKeysReceived.count)",
                amount: amount,
                remainingBalance: amount,
                nextPaymentDate: Date().addingTimeInterval(30 * 86400),
                status: .enRevision,
                termMonths: termMonths,
                interestRate: 0.18,
                monthlyPayment: 2500,
                totalCost: 30000,
                createdAt: Date(),
                installments: []
            )
        }
        throw errorToThrow
    }
}
