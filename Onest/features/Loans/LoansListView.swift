//
//  LoansListView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoansListView: View {
    @StateObject private var viewModel: LoansViewModel
    @State private var selectedLoan: Loan? = nil
    @State private var isPresentingNewLoan: Bool = false

    public init(loanService: LoanServiceProtocol = LoanService.shared) {
        _viewModel = StateObject(wrappedValue: LoansViewModel(loanService: loanService))
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Banner
                        summarySection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // Status Filter Chips
                        filterSection

                        // Main Content
                        if viewModel.isLoading && viewModel.loans.isEmpty {
                            OnestLoadingView(message: "Cargando tus préstamos...")
                                .frame(height: 300)
                        } else if let errorMsg = viewModel.errorMessage, viewModel.loans.isEmpty {
                            OnestErrorView(
                                title: "No pudimos cargar los préstamos",
                                message: errorMsg
                            ) {
                                Task { await viewModel.fetchLoans() }
                            }
                            .frame(height: 350)
                        } else if viewModel.filteredLoans.isEmpty {
                            OnestEmptyStateView(
                                title: "Sin préstamos en este estado",
                                message: "No encontramos préstamos con el filtro seleccionado.",
                                icon: "folder.badge.questionmark"
                            )
                            .frame(height: 300)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.filteredLoans) { loan in
                                    LoanCardView(loan: loan)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedLoan = loan
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 80)
                    }
                }
                .refreshable {
                    await viewModel.refreshLoans()
                }
                .background(OnestTheme.appBackgroundGradient.ignoresSafeArea())
                .navigationTitle("Mis Préstamos")
                .navigationDestination(isPresented: Binding(
                    get: { selectedLoan != nil },
                    set: { if !$0 { selectedLoan = nil } }
                )) {
                    if let loan = selectedLoan {
                        LoanDetailView(loanId: loan.id)
                    }
                }

                // Floating Action Button to Apply for a Loan
                Button {
                    isPresentingNewLoan = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Solicitar Préstamo")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(OnestTheme.primary)
                    .clipShape(Capsule())
                    .shadow(color: OnestTheme.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .sheet(isPresented: $isPresentingNewLoan) {
                    LoanApplicationFlowView {
                        Task { await viewModel.refreshLoans() }
                    }
                }
            }
            .task {
                if viewModel.loans.isEmpty {
                    await viewModel.fetchLoans()
                }
            }
        }
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Deuda Total Pendiente")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))

                Text(CurrencyFormatter.formatDOP(viewModel.totalBalancePending))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Activos")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))

                Text("\(viewModel.activeLoansCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [OnestTheme.mintGreen, OnestTheme.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: OnestTheme.mintGreen.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "Todos", isSelected: viewModel.selectedFilter == nil) {
                    viewModel.selectFilter(nil)
                }

                ForEach(LoanStatus.allCases, id: \.self) { status in
                    filterChip(
                        title: status.title,
                        isSelected: viewModel.selectedFilter == status
                    ) {
                        viewModel.selectFilter(status)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? OnestTheme.textPrimary : OnestTheme.textSecondary)
                .background(isSelected ? OnestTheme.mintGreen : OnestTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : OnestTheme.divider, lineWidth: 1)
                )
        }
    }
}
