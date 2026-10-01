//
//  LoanDetailViewModel.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation
import Combine

@MainActor
public final class LoanDetailViewModel: ObservableObject {
    @Published public var loan: Loan? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isNotFound: Bool = false

    public let loanId: String
    private let loanService: LoanServiceProtocol

    public init(loanId: String, loanService: LoanServiceProtocol = LoanService.shared) {
        self.loanId = loanId
        self.loanService = loanService
    }

    public func fetchDetail() async {
        isLoading = true
        errorMessage = nil
        isNotFound = false

        do {
            let detail = try await loanService.getLoanDetail(id: loanId)
            self.loan = detail
            self.isLoading = false
        } catch let error as APIError {
            self.isLoading = false
            if case .notFound = error {
                self.isNotFound = true
            }
            self.errorMessage = error.localizedDescription
        } catch {
            self.isLoading = false
            self.errorMessage = "No se pudo cargar el detalle del préstamo."
        }
    }
}
