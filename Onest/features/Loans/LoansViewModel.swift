//
//  LoansViewModel.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation
import Combine

@MainActor
public final class LoansViewModel: ObservableObject {
    @Published public var loans: [Loan] = []
    @Published public var isLoading: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var selectedFilter: LoanStatus? = nil

    private let loanService: LoanServiceProtocol

    public init(loanService: LoanServiceProtocol = LoanService.shared) {
        self.loanService = loanService
    }

    public var filteredLoans: [Loan] {
        guard let filter = selectedFilter else { return loans }
        return loans.filter { $0.status == filter }
    }

    public var totalBalancePending: Double {
        loans.filter { $0.status == .desembolsado }.reduce(0) { $0 + $1.remainingBalance }
    }

    public var activeLoansCount: Int {
        loans.filter { $0.status == .desembolsado || $0.status == .aprobado }.count
    }

    public func fetchLoans() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetchedLoans = try await loanService.getLoans()
            self.loans = fetchedLoans
            self.isLoading = false
        } catch let error as APIError {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        } catch {
            self.isLoading = false
            self.errorMessage = "No se pudieron cargar los préstamos. Intenta nuevamente."
        }
    }

    public func refreshLoans() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let fetchedLoans = try await loanService.getLoans()
            self.loans = fetchedLoans
            self.isRefreshing = false
        } catch let error as APIError {
            self.isRefreshing = false
            self.errorMessage = error.localizedDescription
        } catch {
            self.isRefreshing = false
            self.errorMessage = "Error al actualizar los préstamos."
        }
    }

    public func selectFilter(_ status: LoanStatus?) {
        if selectedFilter == status {
            selectedFilter = nil
        } else {
            selectedFilter = status
        }
    }
}
