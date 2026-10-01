//
//  LoanApplicationViewModel.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation
import Combine

public enum ApplicationStep: Int, CaseIterable {
    case amountAndTerm = 1
    case quoteSummary = 2
    case confirmation = 3
}

@MainActor
public final class LoanApplicationViewModel: ObservableObject {
    // Current step
    @Published public var currentStep: ApplicationStep = .amountAndTerm

    // Step 1: Inputs
    @Published public var amount: Double = 25000.0
    @Published public var termMonths: Int = 12
    @Published public var amountString: String = "25000"

    // Validation errors
    @Published public var validationError: String? = nil

    // Step 2: Quote
    @Published public var quote: LoanQuoteResponse? = nil
    @Published public var isCalculatingQuote: Bool = false

    // Step 3: Confirmation & Submission
    @Published public var acceptedTerms: Bool = false
    @Published public var isSubmitting: Bool = false
    @Published public var submissionError: String? = nil
    @Published public var createdLoan: Loan? = nil

    // Idempotency Key - persistent for retries of the same application
    public private(set) var idempotencyKey: String = UUID().uuidString

    private let loanService: LoanServiceProtocol

    public init(loanService: LoanServiceProtocol = LoanService.shared) {
        self.loanService = loanService
    }

    // Boundaries
    public static let minAmount: Double = 5000.0
    public static let maxAmount: Double = 100000.0
    public static let minTerm: Int = 3
    public static let maxTerm: Int = 24

    public var isAmountValid: Bool {
        return amount >= Self.minAmount && amount <= Self.maxAmount
    }

    public var isTermValid: Bool {
        return termMonths >= Self.minTerm && termMonths <= Self.maxTerm
    }

    public func validateStep1() -> Bool {
        validationError = nil

        if let parsed = Double(amountString.replacingOccurrences(of: ",", with: "")) {
            amount = parsed
        }

        if amount < Self.minAmount {
            validationError = "El monto mínimo a solicitar es \(CurrencyFormatter.formatDOP(Self.minAmount))."
            return false
        }

        if amount > Self.maxAmount {
            validationError = "El monto máximo permitido es \(CurrencyFormatter.formatDOP(Self.maxAmount))."
            return false
        }

        if termMonths < Self.minTerm || termMonths > Self.maxTerm {
            validationError = "El plazo debe estar comprendido entre \(Self.minTerm) y \(Self.maxTerm) meses."
            return false
        }

        return true
    }

    public func setQuickAmount(_ value: Double) {
        amount = value
        amountString = String(format: "%.0f", value)
        validationError = nil
    }

    public func calculateQuote() async -> Bool {
        guard validateStep1() else { return false }

        isCalculatingQuote = true
        validationError = nil

        do {
            let quoteResponse = try await loanService.getQuote(amount: amount, termMonths: termMonths)
            self.quote = quoteResponse
            self.isCalculatingQuote = false
            self.currentStep = .quoteSummary
            return true
        } catch let error as APIError {
            self.isCalculatingQuote = false
            self.validationError = error.localizedDescription
            return false
        } catch {
            self.isCalculatingQuote = false
            self.validationError = "Error al calcular la cotización. Intente nuevamente."
            return false
        }
    }

    public func proceedToConfirmation() {
        guard quote != nil else { return }
        currentStep = .confirmation
    }

    public func backToStep1() {
        currentStep = .amountAndTerm
    }

    public func backToStep2() {
        currentStep = .quoteSummary
    }

    public func submitLoanApplication() async -> Bool {
        guard acceptedTerms else {
            submissionError = "Debes aceptar los términos y condiciones para continuar."
            return false
        }

        isSubmitting = true
        submissionError = nil

        do {
            // Uses the stable idempotency key to prevent double loan creation if retried
            let loan = try await loanService.createLoan(
                amount: amount,
                termMonths: termMonths,
                idempotencyKey: idempotencyKey
            )
            self.createdLoan = loan
            self.isSubmitting = false
            return true
        } catch let error as APIError {
            self.isSubmitting = false
            self.submissionError = error.localizedDescription
            return false
        } catch {
            self.isSubmitting = false
            self.submissionError = "Ocurrió un error inesperado al procesar la solicitud."
            return false
        }
    }

    public func regenerateIdempotencyKey() {
        idempotencyKey = UUID().uuidString
    }
}
