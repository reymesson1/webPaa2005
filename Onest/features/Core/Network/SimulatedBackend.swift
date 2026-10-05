//
//  SimulatedBackend.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public final class SimulatedBackend: @unchecked Sendable {
    public static let shared = SimulatedBackend()

    private let lock = NSLock()

    // Configurable flags for tests and behavior simulation
    public var enableRandomLatency: Bool = true
    public var simulateExpiredRefreshToken: Bool = false
    public var simulateAlwaysSuccessPostLoans: Bool = false
    public var simulateAlwaysFailPostLoans: Bool = false

    // State tracking
    private var postLoansRequestCount: Int = 0
    private var activeAccessTokens: [String: Date] = [:] // Token -> Expiration Date
    private var activeRefreshTokens: Set<String> = []
    private var idempotentLoans: [String: Loan] = [:] // Idempotency-Key -> Created Loan

    // Seeded loans
    public private(set) var loans: [Loan] = []

    public init() {
        resetToInitialState()
    }

    public func resetToInitialState() {
        lock.lock()
        defer { lock.unlock() }

        postLoansRequestCount = 0
        activeAccessTokens.removeAll()
        activeRefreshTokens.removeAll()
        idempotentLoans.removeAll()
        enableRandomLatency = true
        simulateExpiredRefreshToken = false
        simulateAlwaysSuccessPostLoans = false
        simulateAlwaysFailPostLoans = false

        // Seed initial tokens
        let defaultAccess = "acc_token_initial_123"
        let defaultRefresh = "ref_token_initial_456"
        activeAccessTokens[defaultAccess] = Date().addingTimeInterval(60)
        activeRefreshTokens.insert(defaultRefresh)

        loans = [
            Loan(
                id: "LOAN-1001",
                amount: 75000.0,
                remainingBalance: 52400.0,
                nextPaymentDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                status: .desembolsado,
                termMonths: 18,
                interestRate: 0.18,
                monthlyPayment: 4786.12,
                totalCost: 86150.16,
                createdAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                installments: Self.generateInstallments(
                    amount: 75000.0,
                    termMonths: 18,
                    monthlyPayment: 4786.12,
                    paidCount: 6,
                    startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                )
            ),
            Loan(
                id: "LOAN-1002",
                amount: 30000.0,
                remainingBalance: 30000.0,
                nextPaymentDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                status: .aprobado,
                termMonths: 12,
                interestRate: 0.18,
                monthlyPayment: 2750.40,
                totalCost: 33004.80,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                installments: Self.generateInstallments(
                    amount: 30000.0,
                    termMonths: 12,
                    monthlyPayment: 2750.40,
                    paidCount: 0,
                    startDate: Date()
                )
            ),
            Loan(
                id: "LOAN-1003",
                amount: 20000.0,
                remainingBalance: 20000.0,
                nextPaymentDate: nil,
                status: .enRevision,
                termMonths: 6,
                interestRate: 0.18,
                monthlyPayment: 3510.50,
                totalCost: 21063.00,
                createdAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date(),
                installments: Self.generateInstallments(
                    amount: 20000.0,
                    termMonths: 6,
                    monthlyPayment: 3510.50,
                    paidCount: 0,
                    startDate: Date()
                )
            ),
            Loan(
                id: "LOAN-1004",
                amount: 15000.0,
                remainingBalance: 0.0,
                nextPaymentDate: nil,
                status: .pagado,
                termMonths: 6,
                interestRate: 0.18,
                monthlyPayment: 2632.88,
                totalCost: 15797.28,
                createdAt: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
                installments: Self.generateInstallments(
                    amount: 15000.0,
                    termMonths: 6,
                    monthlyPayment: 2632.88,
                    paidCount: 6,
                    startDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
                )
            ),
            Loan(
                id: "LOAN-1005",
                amount: 100000.0,
                remainingBalance: 0.0,
                nextPaymentDate: nil,
                status: .rechazado,
                termMonths: 24,
                interestRate: 0.18,
                monthlyPayment: 5000.0,
                totalCost: 120000.0,
                createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                installments: []
            )
        ]
    }

    // MARK: - Validation & Operations

    public func handleLogin(request: LoginRequest) -> (statusCode: Int, body: Data) {
        lock.lock()
        defer { lock.unlock() }

        // Accept user credentials: any non-empty username that has valid email/user and password != "invalid"
        let trimmedUser = request.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = request.password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUser.isEmpty, !trimmedPass.isEmpty, trimmedPass != "invalid", trimmedPass != "error" else {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "Credenciales inválidas. Por favor verifica tu usuario y contraseña."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        let newAccess = "acc_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970))"
        let newRefresh = "ref_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970))"

        let expiresAt = Date().addingTimeInterval(60) // 60 seconds access token
        activeAccessTokens[newAccess] = expiresAt
        activeRefreshTokens.insert(newRefresh)

        let user = User(
            id: "usr_\(abs(trimmedUser.hashValue % 10000))",
            name: trimmedUser.components(separatedBy: "@").first?.capitalized ?? "Ricardo Messon",
            email: trimmedUser.contains("@") ? trimmedUser : "\(trimmedUser)@onest.com"
        )

        let response = AuthResponse(
            accessToken: newAccess,
            refreshToken: newRefresh,
            expiresIn: 60,
            tokenType: "Bearer",
            user: user
        )

        let encoder = JSONEncoder()
        let data = (try? encoder.encode(response)) ?? Data()
        return (200, data)
    }

    public func handleRefresh(request: TokenRefreshRequest) -> (statusCode: Int, body: Data) {
        lock.lock()
        defer { lock.unlock() }

        if simulateExpiredRefreshToken || !activeRefreshTokens.contains(request.refreshToken) {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "El token de actualización ha expirado o no es válido. Inicia sesión nuevamente."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        let newAccess = "acc_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970))"
        let newRefresh = "ref_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970))"

        activeAccessTokens[newAccess] = Date().addingTimeInterval(60)
        activeRefreshTokens.remove(request.refreshToken)
        activeRefreshTokens.insert(newRefresh)

        let response = TokenRefreshResponse(
            accessToken: newAccess,
            refreshToken: newRefresh,
            expiresIn: 60,
            tokenType: "Bearer"
        )

        let encoder = JSONEncoder()
        let data = (try? encoder.encode(response)) ?? Data()
        return (200, data)
    }

    public func validateAuthHeader(_ authHeader: String?) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let authHeader = authHeader, authHeader.hasPrefix("Bearer ") else {
            return false
        }

        let token = String(authHeader.dropFirst(7)).trimmingCharacters(in: .whitespaces)

        // Check if token exists and hasn't expired
        guard let expiration = activeAccessTokens[token] else {
            return false
        }

        if Date() >= expiration {
            return false
        }

        return true
    }

    public func handleGetLoans(authHeader: String?) -> (statusCode: Int, body: Data) {
        guard validateAuthHeader(authHeader) else {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "El token de acceso ha expirado o no es válido."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        lock.lock()
        let currentLoans = loans
        lock.unlock()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(currentLoans)) ?? Data()
        return (200, data)
    }

    public func handleGetLoanDetail(id: String, authHeader: String?) -> (statusCode: Int, body: Data) {
        guard validateAuthHeader(authHeader) else {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "El token de acceso ha expirado o no es válido."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        lock.lock()
        let loan = loans.first { $0.id == id }
        lock.unlock()

        guard let foundLoan = loan else {
            let errorJson = """
            {
                "error": "NOT_FOUND",
                "message": "No se encontró ningún préstamo con el identificador especificado."
            }
            """
            return (404, errorJson.data(using: .utf8)!)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(foundLoan)) ?? Data()
        return (200, data)
    }

    public func handleQuote(request: LoanQuoteRequest, authHeader: String?) -> (statusCode: Int, body: Data) {
        guard validateAuthHeader(authHeader) else {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "El token de acceso ha expirado o no es válido."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        // Validate bounds: amount 5,000 - 100,000 DOP, term 3 - 24 months
        guard request.amount >= 5000.0 && request.amount <= 100000.0 &&
              request.termMonths >= 3 && request.termMonths <= 24 else {
            let errorJson = """
            {
                "error": "UNPROCESSABLE_ENTITY",
                "message": "El monto debe estar entre RD$ 5,000 y RD$ 100,000 y el plazo entre 3 y 24 meses."
            }
            """
            return (422, errorJson.data(using: .utf8)!)
        }

        let annualRate = 0.18 // 18% annual APR
        let monthlyRate = annualRate / 12.0
        let n = Double(request.termMonths)

        // French amortization: PMT = P * (r * (1 + r)^n) / ((1 + r)^n - 1)
        let factor = pow(1.0 + monthlyRate, n)
        let monthlyPayment = (request.amount * (monthlyRate * factor)) / (factor - 1.0)
        let roundedMonthlyPayment = (monthlyPayment * 100).rounded() / 100.0
        let totalCost = (roundedMonthlyPayment * n * 100).rounded() / 100.0
        let totalInterest = ((totalCost - request.amount) * 100).rounded() / 100.0

        let response = LoanQuoteResponse(
            amount: request.amount,
            termMonths: request.termMonths,
            annualRate: annualRate,
            monthlyPayment: roundedMonthlyPayment,
            totalCost: totalCost,
            totalInterest: totalInterest
        )

        let encoder = JSONEncoder()
        let data = (try? encoder.encode(response)) ?? Data()
        return (200, data)
    }

    public func handleCreateLoan(
        request: CreateLoanRequest,
        idempotencyKey: String?,
        authHeader: String?
    ) -> (statusCode: Int, body: Data) {
        guard validateAuthHeader(authHeader) else {
            let errorJson = """
            {
                "error": "UNAUTHORIZED",
                "message": "El token de acceso ha expirado o no es válido."
            }
            """
            return (401, errorJson.data(using: .utf8)!)
        }

        guard let key = idempotencyKey, !key.trimmingCharacters(in: .whitespaces).isEmpty else {
            let errorJson = """
            {
                "error": "BAD_REQUEST",
                "message": "Se requiere el encabezado Idempotency-Key para garantizar la idempotencia de la solicitud."
            }
            """
            return (400, errorJson.data(using: .utf8)!)
        }

        lock.lock()
        defer { lock.unlock() }

        // Idempotency check: if key already exists, return existing loan
        if let existingLoan = idempotentLoans[key] {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = (try? encoder.encode(existingLoan)) ?? Data()
            return (200, data) // Returning same loan
        }

        postLoansRequestCount += 1

        // Intermittent 500 error: 1 in every 4 requests (i.e., request % 4 == 0)
        let shouldFail500: Bool
        if simulateAlwaysFailPostLoans {
            shouldFail500 = true
        } else if simulateAlwaysSuccessPostLoans {
            shouldFail500 = false
        } else {
            shouldFail500 = (postLoansRequestCount % 4 == 0)
        }

        if shouldFail500 {
            let errorJson = """
            {
                "error": "INTERNAL_SERVER_ERROR",
                "message": "Error intermitente en el servicio de desembolso (500). Por favor reintente con la misma Idempotency-Key."
            }
            """
            return (500, errorJson.data(using: .utf8)!)
        }

        // Validate amount and term
        guard request.amount >= 5000.0 && request.amount <= 100000.0 &&
              request.termMonths >= 3 && request.termMonths <= 24 else {
            let errorJson = """
            {
                "error": "UNPROCESSABLE_ENTITY",
                "message": "El monto debe estar entre RD$ 5,000 y RD$ 100,000 y el plazo entre 3 y 24 meses."
            }
            """
            return (422, errorJson.data(using: .utf8)!)
        }

        let annualRate = 0.18
        let monthlyRate = annualRate / 12.0
        let n = Double(request.termMonths)
        let factor = pow(1.0 + monthlyRate, n)
        let monthlyPayment = (request.amount * (monthlyRate * factor)) / (factor - 1.0)
        let roundedMonthlyPayment = (monthlyPayment * 100).rounded() / 100.0
        let totalCost = (roundedMonthlyPayment * n * 100).rounded() / 100.0

        let newLoanId = "LOAN-\(2000 + loans.count + 1)"
        let nextPayDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())

        let installments = Self.generateInstallments(
            amount: request.amount,
            termMonths: request.termMonths,
            monthlyPayment: roundedMonthlyPayment,
            paidCount: 0,
            startDate: Date()
        )

        let newLoan = Loan(
            id: newLoanId,
            amount: request.amount,
            remainingBalance: request.amount,
            nextPaymentDate: nextPayDate,
            status: .enRevision,
            termMonths: request.termMonths,
            interestRate: annualRate,
            monthlyPayment: roundedMonthlyPayment,
            totalCost: totalCost,
            createdAt: Date(),
            installments: installments
        )

        // Store under idempotency key and loans collection
        idempotentLoans[key] = newLoan
        loans.insert(newLoan, at: 0)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(newLoan)) ?? Data()
        return (201, data)
    }

    // MARK: - Helpers

    public static func generateInstallments(
        amount: Double,
        termMonths: Int,
        monthlyPayment: Double,
        paidCount: Int,
        startDate: Date
    ) -> [PaymentInstallment] {
        var installments: [PaymentInstallment] = []
        var remainingPrincipal = amount
        let monthlyRate = 0.18 / 12.0

        for i in 1...termMonths {
            let dueDate = Calendar.current.date(byAdding: .month, value: i, to: startDate) ?? startDate
            let interest = (remainingPrincipal * monthlyRate * 100).rounded() / 100.0
            let principal = min(remainingPrincipal, ((monthlyPayment - interest) * 100).rounded() / 100.0)
            remainingPrincipal = max(0, remainingPrincipal - principal)

            let status: InstallmentStatus
            if i <= paidCount {
                status = .pagado
            } else if i == paidCount + 1 && dueDate < Date() {
                status = .vencido
            } else {
                status = .pendiente
            }

            installments.append(PaymentInstallment(
                installmentNumber: i,
                dueDate: dueDate,
                amount: monthlyPayment,
                principal: principal,
                interest: interest,
                status: status
            ))
        }

        return installments
    }
}
