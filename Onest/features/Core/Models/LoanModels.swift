//
//  LoanModels.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public enum LoanStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case enRevision = "EN_REVISION"
    case aprobado = "APROBADO"
    case desembolsado = "DESEMBOLSADO"
    case rechazado = "RECHAZADO"
    case pagado = "PAGADO"

    public var title: String {
        switch self {
        case .enRevision: return "En Revisión"
        case .aprobado: return "Aprobado"
        case .desembolsado: return "Desembolsado"
        case .rechazado: return "Rechazado"
        case .pagado: return "Pagado"
        }
    }

    public var systemIcon: String {
        switch self {
        case .enRevision: return "clock.arrow.circlepath"
        case .aprobado: return "checkmark.seal.fill"
        case .desembolsado: return "banknote.fill"
        case .rechazado: return "xmark.circle.fill"
        case .pagado: return "checkmark.circle.fill"
        }
    }
}

public enum InstallmentStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case pagado = "PAGADO"
    case pendiente = "PENDIENTE"
    case vencido = "VENCIDO"

    public var title: String {
        switch self {
        case .pagado: return "Pagado"
        case .pendiente: return "Pendiente"
        case .vencido: return "Vencido"
        }
    }
}

public struct PaymentInstallment: Codable, Identifiable, Equatable, Sendable {
    public var id: Int { installmentNumber }
    public let installmentNumber: Int
    public let dueDate: Date
    public let amount: Double
    public let principal: Double
    public let interest: Double
    public let status: InstallmentStatus

    public init(
        installmentNumber: Int,
        dueDate: Date,
        amount: Double,
        principal: Double,
        interest: Double,
        status: InstallmentStatus
    ) {
        self.installmentNumber = installmentNumber
        self.dueDate = dueDate
        self.amount = amount
        self.principal = principal
        self.interest = interest
        self.status = status
    }
}

public struct Loan: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let amount: Double
    public let remainingBalance: Double
    public let nextPaymentDate: Date?
    public let status: LoanStatus
    public let termMonths: Int
    public let interestRate: Double // e.g. 0.18 for 18% APR
    public let monthlyPayment: Double
    public let totalCost: Double
    public let createdAt: Date
    public var installments: [PaymentInstallment]?

    public init(
        id: String,
        amount: Double,
        remainingBalance: Double,
        nextPaymentDate: Date?,
        status: LoanStatus,
        termMonths: Int,
        interestRate: Double,
        monthlyPayment: Double,
        totalCost: Double,
        createdAt: Date,
        installments: [PaymentInstallment]? = nil
    ) {
        self.id = id
        self.amount = amount
        self.remainingBalance = remainingBalance
        self.nextPaymentDate = nextPaymentDate
        self.status = status
        self.termMonths = termMonths
        self.interestRate = interestRate
        self.monthlyPayment = monthlyPayment
        self.totalCost = totalCost
        self.createdAt = createdAt
        self.installments = installments
    }
}

public struct LoanQuoteRequest: Codable, Equatable, Sendable {
    public let amount: Double
    public let termMonths: Int

    public init(amount: Double, termMonths: Int) {
        self.amount = amount
        self.termMonths = termMonths
    }
}

public struct LoanQuoteResponse: Codable, Equatable, Sendable {
    public let amount: Double
    public let termMonths: Int
    public let annualRate: Double
    public let monthlyPayment: Double
    public let totalCost: Double
    public let totalInterest: Double

    public init(
        amount: Double,
        termMonths: Int,
        annualRate: Double,
        monthlyPayment: Double,
        totalCost: Double,
        totalInterest: Double
    ) {
        self.amount = amount
        self.termMonths = termMonths
        self.annualRate = annualRate
        self.monthlyPayment = monthlyPayment
        self.totalCost = totalCost
        self.totalInterest = totalInterest
    }
}

public struct CreateLoanRequest: Codable, Equatable, Sendable {
    public let amount: Double
    public let termMonths: Int

    public init(amount: Double, termMonths: Int) {
        self.amount = amount
        self.termMonths = termMonths
    }
}
