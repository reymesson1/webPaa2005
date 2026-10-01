//
//  LoanDetailView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoanDetailView: View {
    @StateObject private var viewModel: LoanDetailViewModel

    public init(loanId: String, loanService: LoanServiceProtocol = LoanService.shared) {
        _viewModel = StateObject(wrappedValue: LoanDetailViewModel(loanId: loanId, loanService: loanService))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.loan == nil {
                    OnestLoadingView(message: "Cargando detalle del préstamo...")
                        .frame(height: 350)
                } else if viewModel.isNotFound {
                    OnestEmptyStateView(
                        title: "Préstamo no encontrado (404)",
                        message: "El préstamo solicitado no existe o fue eliminado del sistema.",
                        icon: "magnifyingglass"
                    )
                    .frame(height: 350)
                } else if let errorMsg = viewModel.errorMessage, viewModel.loan == nil {
                    OnestErrorView(
                        title: "Error al cargar detalle",
                        message: errorMsg
                    ) {
                        Task { await viewModel.fetchDetail() }
                    }
                    .frame(height: 350)
                } else if let loan = viewModel.loan {
                    loanHeaderSection(loan)
                    loanSpecsGrid(loan)

                    if let installments = loan.installments, !installments.isEmpty {
                        PaymentCalendarView(installments: installments)
                    } else {
                        OnestEmptyStateView(
                            title: "Sin calendario de pagos",
                            message: "Este préstamo aún no cuenta con un calendario de cuotas generado.",
                            icon: "calendar.badge.exclamationmark"
                        )
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(OnestTheme.background.ignoresSafeArea())
        .navigationTitle(viewModel.loanId)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDetail()
        }
    }

    private func loanHeaderSection(_ loan: Loan) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("Detalle del Crédito")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnestTheme.textSecondary)

                Spacer()

                LoanStatusBadge(status: loan.status)
            }

            VStack(spacing: 4) {
                Text("Saldo Pendiente")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(OnestTheme.textSecondary)

                Text(CurrencyFormatter.formatDOP(loan.remainingBalance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(loan.remainingBalance > 0 ? OnestTheme.primary : OnestTheme.textSecondary)
            }

            if let nextDate = loan.nextPaymentDate, loan.status == .desembolsado || loan.status == .aprobado {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(OnestTheme.primary)
                    Text("Próximo pago: \(AppDateFormatters.formatFull(nextDate))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OnestTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(OnestTheme.primaryLight)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(OnestTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func loanSpecsGrid(_ loan: Loan) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                specItem(title: "Monto Original", value: CurrencyFormatter.formatDOP(loan.amount))
                specItem(title: "Cuota Mensual", value: CurrencyFormatter.formatDOP(loan.monthlyPayment))
            }

            HStack(spacing: 12) {
                specItem(title: "Plazo", value: "\(loan.termMonths) meses")
                specItem(title: "Tasa de Interés (APR)", value: CurrencyFormatter.formatPercentage(loan.interestRate))
            }

            HStack(spacing: 12) {
                specItem(title: "Costo Total", value: CurrencyFormatter.formatDOP(loan.totalCost))
                specItem(title: "Fecha Solicitud", value: AppDateFormatters.formatShort(loan.createdAt))
            }
        }
    }

    private func specItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(OnestTheme.textSecondary)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(OnestTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(OnestTheme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(OnestTheme.divider, lineWidth: 1)
        )
    }
}
