//
//  Step3ConfirmationView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct Step3ConfirmationView: View {
    @ObservedObject public var viewModel: LoanApplicationViewModel
    public let onFinished: () -> Void

    public init(viewModel: LoanApplicationViewModel, onFinished: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onFinished = onFinished
    }

    public var body: some View {
        VStack(spacing: 24) {
            if let createdLoan = viewModel.createdLoan {
                successState(createdLoan)
            } else {
                confirmationForm
            }
        }
    }

    private var confirmationForm: some View {
        VStack(spacing: 22) {
            // Intro
            VStack(alignment: .leading, spacing: 6) {
                Text("Paso 3 de 3: Confirmación")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnestTheme.primary)

                Text("Confirma tu Solicitud")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)

                Text("Revisa los datos antes de enviar tu crédito a evaluación.")
                    .font(.system(size: 14))
                    .foregroundColor(OnestTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Final Summary Card
            VStack(spacing: 14) {
                HStack {
                    Text("Resumen Final")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(OnestTheme.textPrimary)
                    Spacer()
                    LoanStatusBadge(status: .enRevision)
                }

                Divider()

                summaryItem(title: "Monto:", value: CurrencyFormatter.formatDOP(viewModel.amount))
                summaryItem(title: "Plazo:", value: "\(viewModel.termMonths) meses")
                if let quote = viewModel.quote {
                    summaryItem(title: "Cuota Mensual:", value: CurrencyFormatter.formatDOP(quote.monthlyPayment))
                    summaryItem(title: "Costo Total:", value: CurrencyFormatter.formatDOP(quote.totalCost))
                }
            }
            .padding(20)
            .background(OnestTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

            // Idempotency Key Info Badge (demonstrating technical constraint)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12))
                        .foregroundColor(OnestTheme.secondary)
                    Text("Idempotency-Key asignada:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnestTheme.textSecondary)
                }
                Text(viewModel.idempotencyKey)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(OnestTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(OnestTheme.background)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(OnestTheme.divider, lineWidth: 1)
            )

            // Intermittent 500 or Other Error Notice
            if let errorMsg = viewModel.submissionError {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(red: 229/255, green: 57/255, blue: 53/255))
                        Text("Error de Envío")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))
                    }

                    Text(errorMsg)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))

                    Text("Puedes reintentar inmediatamente: se preserva la misma Idempotency-Key para garantizar que no se dupliquen cargos o préstamos.")
                        .font(.system(size: 11))
                        .foregroundColor(OnestTheme.textSecondary)
                        .padding(.top, 2)
                }
                .padding()
                .background(Color(red: 255/255, green: 235/255, blue: 238/255))
                .cornerRadius(12)
            }

            // Terms Checkbox
            Button {
                viewModel.acceptedTerms.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.acceptedTerms ? OnestTheme.primary : OnestTheme.textSecondary)

                    Text("He leído y acepto los Términos y Condiciones del Crédito Digital Onest Lite.")
                        .font(.system(size: 13))
                        .foregroundColor(OnestTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 4)

            // Action Buttons
            VStack(spacing: 12) {
                OnestButton(
                    title: viewModel.submissionError != nil ? "Reintentar Solicitud (Misma Key)" : "Confirmar y Solicitar Préstamo",
                    icon: "paperplane.fill",
                    style: .primary,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.acceptedTerms
                ) {
                    Task {
                        _ = await viewModel.submitLoanApplication()
                    }
                }

                OnestButton(
                    title: "Volver a Condiciones",
                    icon: "arrow.left",
                    style: .outline,
                    isEnabled: !viewModel.isSubmitting
                ) {
                    viewModel.backToStep2()
                }
            }
        }
    }

    private func successState(_ loan: Loan) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(OnestTheme.primaryLight)
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(OnestTheme.primary)
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                Text("¡Solicitud Recibida!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)

                Text("Tu préstamo ha sido registrado y se encuentra en revisión.")
                    .font(.system(size: 14))
                    .foregroundColor(OnestTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                summaryItem(title: "Código de Solicitud:", value: loan.id)
                summaryItem(title: "Monto:", value: CurrencyFormatter.formatDOP(loan.amount))
                summaryItem(title: "Estado:", value: loan.status.title)
                summaryItem(title: "Plazo:", value: "\(loan.termMonths) meses")
                summaryItem(title: "Cuota:", value: CurrencyFormatter.formatDOP(loan.monthlyPayment))
            }
            .padding(20)
            .background(OnestTheme.cardBackground)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

            OnestButton(
                title: "Ver en Mis Préstamos",
                icon: "arrow.right",
                style: .primary
            ) {
                onFinished()
            }
        }
    }

    private func summaryItem(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(OnestTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(OnestTheme.textPrimary)
        }
    }
}
