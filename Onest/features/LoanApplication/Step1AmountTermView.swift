//
//  Step1AmountTermView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct Step1AmountTermView: View {
    @ObservedObject public var viewModel: LoanApplicationViewModel

    private let quickAmounts: [Double] = [10000, 25000, 50000, 75000, 100000]
    private let terms: [Int] = [3, 6, 12, 18, 24]

    public init(viewModel: LoanApplicationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Intro
            VStack(alignment: .leading, spacing: 6) {
                Text("Paso 1 de 3: Monto y Plazo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnestTheme.primary)

                Text("¿Cuánto dinero necesitas?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)

                Text("Elige un monto entre RD$ 5,000 y RD$ 100,000 en cuotas fijas.")
                    .font(.system(size: 14))
                    .foregroundColor(OnestTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Amount Selection Card
            VStack(spacing: 16) {
                Text("Monto a Solicitar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OnestTheme.textSecondary)

                Text(CurrencyFormatter.formatDOP(viewModel.amount))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(OnestTheme.primary)

                // Slider
                Slider(
                    value: $viewModel.amount,
                    in: LoanApplicationViewModel.minAmount...LoanApplicationViewModel.maxAmount,
                    step: 1000
                )
                .tint(OnestTheme.primary)
                .onChange(of: viewModel.amount) { newValue in
                    viewModel.amountString = String(format: "%.0f", newValue)
                    viewModel.validationError = nil
                }

                HStack {
                    Text(CurrencyFormatter.formatDOP(LoanApplicationViewModel.minAmount, includeDecimals: false))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                    Spacer()
                    Text(CurrencyFormatter.formatDOP(LoanApplicationViewModel.maxAmount, includeDecimals: false))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                }

                // Quick chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { val in
                            Button {
                                viewModel.setQuickAmount(val)
                            } label: {
                                Text(CurrencyFormatter.formatDOP(val, includeDecimals: false))
                                    .font(.system(size: 12, weight: viewModel.amount == val ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundColor(viewModel.amount == val ? .white : OnestTheme.textPrimary)
                                    .background(viewModel.amount == val ? OnestTheme.primary : OnestTheme.divider)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(OnestTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

            // Term Selection Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Plazo en Meses")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(OnestTheme.textSecondary)
                    Spacer()
                    Text("\(viewModel.termMonths) meses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OnestTheme.primary)
                }

                HStack(spacing: 10) {
                    ForEach(terms, id: \.self) { term in
                        Button {
                            viewModel.termMonths = term
                            viewModel.validationError = nil
                        } label: {
                            Text("\(term) m")
                                .font(.system(size: 14, weight: viewModel.termMonths == term ? .bold : .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(viewModel.termMonths == term ? .white : OnestTheme.textPrimary)
                                .background(viewModel.termMonths == term ? OnestTheme.primary : OnestTheme.divider)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(20)
            .background(OnestTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

            // Error notice
            if let errorMsg = viewModel.validationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMsg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color(red: 255/255, green: 235/255, blue: 238/255))
                .cornerRadius(12)
            }

            // Continue CTA
            OnestButton(
                title: "Calcular Condiciones",
                icon: "arrow.right",
                style: .primary,
                isLoading: viewModel.isCalculatingQuote,
                isEnabled: viewModel.isAmountValid && viewModel.isTermValid
            ) {
                Task {
                    _ = await viewModel.calculateQuote()
                }
            }
            .padding(.top, 8)
        }
    }
}
