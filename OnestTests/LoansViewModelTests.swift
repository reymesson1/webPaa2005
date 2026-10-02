//
//  LoansViewModelTests.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

#if canImport(Onest)
@testable import Onest
#endif

@MainActor
final class LoansViewModelTests: XCTestCase {

    private var mockService: MockLoanService!
    private var viewModel: LoansViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockLoanService()
        mockService.mockLoans = [
            Loan(
                id: "LOAN-1",
                amount: 50000,
                remainingBalance: 30000,
                nextPaymentDate: Date(),
                status: .desembolsado,
                termMonths: 12,
                interestRate: 0.18,
                monthlyPayment: 4500,
                totalCost: 54000,
                createdAt: Date()
            ),
            Loan(
                id: "LOAN-2",
                amount: 25000,
                remainingBalance: 25000,
                nextPaymentDate: Date(),
                status: .aprobado,
                termMonths: 6,
                interestRate: 0.18,
                monthlyPayment: 4300,
                totalCost: 25800,
                createdAt: Date()
            ),
            Loan(
                id: "LOAN-3",
                amount: 15000,
                remainingBalance: 0,
                nextPaymentDate: nil,
                status: .pagado,
                termMonths: 6,
                interestRate: 0.18,
                monthlyPayment: 2600,
                totalCost: 15600,
                createdAt: Date()
            ),
            Loan(
                id: "LOAN-4",
                amount: 20000,
                remainingBalance: 20000,
                nextPaymentDate: nil,
                status: .enRevision,
                termMonths: 12,
                interestRate: 0.18,
                monthlyPayment: 1800,
                totalCost: 21600,
                createdAt: Date()
            )
        ]
        viewModel = LoansViewModel(loanService: mockService)
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.loans.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedFilter)
    }

    func testFetchLoansSuccess() async {
        await viewModel.fetchLoans()

        XCTAssertEqual(viewModel.loans.count, 4)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchLoansFailureSetsErrorMessage() async {
        mockService.shouldSucceed = false
        mockService.errorToThrow = .unauthorized(message: "Sesión expirada")

        await viewModel.fetchLoans()

        XCTAssertTrue(viewModel.loans.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Sesión expirada")
    }

    func testFilterLoansByStatus() async {
        await viewModel.fetchLoans()

        // Filter by Desembolsado
        viewModel.selectFilter(.desembolsado)
        XCTAssertEqual(viewModel.filteredLoans.count, 1)
        XCTAssertEqual(viewModel.filteredLoans.first?.id, "LOAN-1")

        // Filter by Pagado
        viewModel.selectFilter(.pagado)
        XCTAssertEqual(viewModel.filteredLoans.count, 1)
        XCTAssertEqual(viewModel.filteredLoans.first?.id, "LOAN-3")

        // Toggle same filter off -> resets to all
        viewModel.selectFilter(.pagado)
        XCTAssertEqual(viewModel.filteredLoans.count, 4)
    }

    func testTotalBalancePendingCalculation() async {
        await viewModel.fetchLoans()

        // Only desembolsado remaining balances should sum to pending balance (30,000)
        XCTAssertEqual(viewModel.totalBalancePending, 30000)
    }

    func testActiveLoansCountCalculation() async {
        await viewModel.fetchLoans()

        // Desembolsado (LOAN-1) + Aprobado (LOAN-2) = 2 active loans
        XCTAssertEqual(viewModel.activeLoansCount, 2)
    }

    func testRefreshLoans() async {
        await viewModel.fetchLoans()
        XCTAssertEqual(viewModel.loans.count, 4)

        // Add 5th loan on service
        mockService.mockLoans.append(
            Loan(
                id: "LOAN-5",
                amount: 10000,
                remainingBalance: 10000,
                nextPaymentDate: nil,
                status: .enRevision,
                termMonths: 3,
                interestRate: 0.18,
                monthlyPayment: 3400,
                totalCost: 10200,
                createdAt: Date()
            )
        )

        await viewModel.refreshLoans()

        XCTAssertEqual(viewModel.loans.count, 5)
        XCTAssertFalse(viewModel.isRefreshing)
    }
}
