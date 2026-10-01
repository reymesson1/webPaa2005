//
//  LoanApplicationFlowView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoanApplicationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LoanApplicationViewModel
    public let onLoanCreated: () -> Void

    public init(
        loanService: LoanServiceProtocol = LoanService.shared,
        onLoanCreated: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: LoanApplicationViewModel(loanService: loanService))
        self.onLoanCreated = onLoanCreated
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Step Progress Indicator
                    stepIndicator

                    switch viewModel.currentStep {
                    case .amountAndTerm:
                        Step1AmountTermView(viewModel: viewModel)
                    case .quoteSummary:
                        Step2ConditionsView(viewModel: viewModel)
                    case .confirmation:
                        Step3ConfirmationView(viewModel: viewModel) {
                            onLoanCreated()
                            dismiss()
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(OnestTheme.background.ignoresSafeArea())
            .navigationTitle("Solicitar Préstamo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(OnestTheme.textSecondary)
                }
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(ApplicationStep.allCases, id: \.self) { step in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= viewModel.currentStep.rawValue ? OnestTheme.primary : OnestTheme.divider)
                            .frame(width: 26, height: 26)

                        if step.rawValue < viewModel.currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.rawValue)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(step == viewModel.currentStep ? .white : OnestTheme.textSecondary)
                        }
                    }

                    Text(stepTitle(step))
                        .font(.system(size: 12, weight: step == viewModel.currentStep ? .bold : .medium))
                        .foregroundColor(step == viewModel.currentStep ? OnestTheme.textPrimary : OnestTheme.textSecondary)
                }

                if step != .confirmation {
                    Rectangle()
                        .fill(step.rawValue < viewModel.currentStep.rawValue ? OnestTheme.primary : OnestTheme.divider)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func stepTitle(_ step: ApplicationStep) -> String {
        switch step {
        case .amountAndTerm: return "Monto"
        case .quoteSummary: return "Condiciones"
        case .confirmation: return "Confirmar"
        }
    }
}
