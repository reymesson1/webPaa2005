//
//  Step2ConditionsView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct Step2ConditionsView: View {
    @ObservedObject public var viewModel: LoanApplicationViewModel

    public init(viewModel: LoanApplicationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Intro
            VStack(alignment: .leading, spacing: 6) {
                Text("Paso 2 de 3: Resumen de Condiciones")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnestTheme.primary)

                Text("Tus condiciones de crédito")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)

                Text("Transparencia total: sin costos ocultos ni penalidades por pago anticipado.")
                    .font(.system(size: 14))
                    .foregroundColor(OnestTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let quote = viewModel.quote {
                // Monthly Installment Hero Card
                VStack(spacing: 8) {
                    Text("Tu Cuota Mensual Estimada")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(OnestTheme.primaryLight)

                    Text(CurrencyFormatter.formatDOP(quote.monthlyPayment))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Durante \(quote.termMonths) meses consecutivos")
                        .font(.system(size: 13))
                        .foregroundColor(OnestTheme.primaryLight.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [OnestTheme.primary, OnestTheme.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: OnestTheme.primary.opacity(0.25), radius: 10, x: 0, y: 5)

                // Breakdown Specs
                VStack(spacing: 14) {
                    conditionRow(
                        title: "Monto Solicitado",
                        value: CurrencyFormatter.formatDOP(quote.amount),
                        highlight: false
                    )

                    Divider()

                    conditionRow(
                        title: "Plazo",
                        value: "\(quote.termMonths) meses",
                        highlight: false
                    )

                    Divider()

                    conditionRow(
                        title: "Tasa de Interés Anual (APR)",
                        value: CurrencyFormatter.formatPercentage(quote.annualRate),
                        highlight: false
                    )

                    Divider()

                    conditionRow(
                        title: "Total de Intereses",
                        value: CurrencyFormatter.formatDOP(quote.totalInterest),
                        highlight: false
                    )

                    Divider()

                    conditionRow(
                        title: "Costo Total del Crédito",
                        value: CurrencyFormatter.formatDOP(quote.totalCost),
                        highlight: true
                    )
                }
                .padding(20)
                .background(OnestTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

                // Navigation Buttons
                VStack(spacing: 12) {
                    OnestButton(
                        title: "Continuar a Confirmación",
                        icon: "arrow.right",
                        style: .primary
                    ) {
                        viewModel.proceedToConfirmation()
                    }

                    OnestButton(
                        title: "Modificar Monto o Plazo",
                        icon: "arrow.left",
                        style: .outline
                    ) {
                        viewModel.backToStep1()
                    }
                }
            } else {
                OnestErrorView(
                    title: "Cotización no disponible",
                    message: "Por favor regresa al paso 1 para calcular tu cotización."
                ) {
                    viewModel.backToStep1()
                }
            }
        }
    }

    private func conditionRow(title: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: highlight ? .bold : .medium))
                .foregroundColor(highlight ? OnestTheme.textPrimary : OnestTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: highlight ? 17 : 15, weight: .bold, design: .rounded))
                .foregroundColor(highlight ? OnestTheme.primary : OnestTheme.textPrimary)
        }
    }
}
