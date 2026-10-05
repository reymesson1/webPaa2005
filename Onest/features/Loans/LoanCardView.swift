//
//  LoanCardView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoanCardView: View {
    public let loan: Loan

    public init(loan: Loan) {
        self.loan = loan
    }

    private var progress: Double {
        guard loan.amount > 0 else { return 0 }
        let paid = max(0, loan.amount - loan.remainingBalance)
        return min(1.0, paid / loan.amount)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: ID and Status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loan.id)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(OnestTheme.textSecondary)
                    Text("Plazo: \(loan.termMonths) meses")
                        .font(.system(size: 12))
                        .foregroundColor(OnestTheme.textSecondary)
                }

                Spacer()

                LoanStatusBadge(status: loan.status)
            }

            Divider()
                .background(OnestTheme.divider)

            // Amounts Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monto solicitado")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                    Text(CurrencyFormatter.formatDOP(loan.amount))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(OnestTheme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Saldo pendiente")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                    Text(CurrencyFormatter.formatDOP(loan.remainingBalance))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(loan.remainingBalance > 0 ? OnestTheme.primary : OnestTheme.textSecondary)
                }
            }

            // Progress bar for active / disbursed loans
            if loan.status == .desembolsado || loan.status == .pagado {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(OnestTheme.primaryLight)
                                .frame(height: 6)

                            Capsule()
                                .fill(OnestTheme.primary)
                                .frame(width: max(6, geo.size.width * CGFloat(progress)), height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(Int(progress * 100))% amortizado")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(OnestTheme.primary)
                        Spacer()
                    }
                }
            }

            // Footer: Next payment date & Monthly Installment
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(OnestTheme.textSecondary)

                    if let nextDate = loan.nextPaymentDate, loan.status == .desembolsado || loan.status == .aprobado {
                        Text("Próximo pago: \(AppDateFormatters.formatShort(nextDate))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(OnestTheme.textPrimary)
                    } else if loan.status == .pagado {
                        Text("Completado")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(OnestTheme.textSecondary)
                    } else {
                        Text("En proceso de evaluación")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(OnestTheme.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Detalles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnestTheme.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(OnestTheme.primary)
                }
            }
        }
        .padding(18)
        .background(OnestTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
