//
//  PaymentCalendarView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct PaymentCalendarView: View {
    public let installments: [PaymentInstallment]

    @State private var filter: InstallmentStatus? = nil

    public init(installments: [PaymentInstallment]) {
        self.installments = installments
    }

    private var filteredInstallments: [PaymentInstallment] {
        guard let filter = filter else { return installments }
        return installments.filter { $0.status == filter }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Filter Tabs
            HStack {
                Text("Calendario de Pagos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)

                Spacer()

                Text("\(installments.count) cuotas")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(OnestTheme.textSecondary)
            }

            // Quick Status Filter
            HStack(spacing: 8) {
                filterButton(title: "Todas", isSelected: filter == nil) {
                    filter = nil
                }
                filterButton(title: "Pagadas", isSelected: filter == .pagado) {
                    filter = .pagado
                }
                filterButton(title: "Pendientes", isSelected: filter == .pendiente) {
                    filter = .pendiente
                }
            }

            // Installment List
            if filteredInstallments.isEmpty {
                Text("No hay cuotas con el estado seleccionado.")
                    .font(.system(size: 13))
                    .foregroundColor(OnestTheme.textSecondary)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredInstallments) { item in
                        installmentRow(item)
                    }
                }
            }
        }
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(isSelected ? .white : OnestTheme.textSecondary)
                .background(isSelected ? OnestTheme.primary : OnestTheme.divider)
                .clipShape(Capsule())
        }
    }

    private func installmentRow(_ item: PaymentInstallment) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Cuota #\(item.installmentNumber)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(OnestTheme.textPrimary)

                        InstallmentStatusBadge(status: item.status)
                    }

                    Text("Vence: \(AppDateFormatters.formatShort(item.dueDate))")
                        .font(.system(size: 12))
                        .foregroundColor(OnestTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.formatDOP(item.amount))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(OnestTheme.textPrimary)

                    Text("Capital: \(CurrencyFormatter.formatDOP(item.principal))")
                        .font(.system(size: 11))
                        .foregroundColor(OnestTheme.textSecondary)
                }
            }

            HStack {
                Text("Interés: \(CurrencyFormatter.formatDOP(item.interest))")
                    .font(.system(size: 11))
                    .foregroundColor(OnestTheme.textSecondary)
                Spacer()
            }
        }
        .padding(14)
        .background(OnestTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OnestTheme.divider, lineWidth: 1)
        )
    }
}
