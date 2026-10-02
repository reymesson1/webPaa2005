//
//  LoanApplicationValidationTests.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

#if canImport(Onest)
@testable import Onest
#endif

@MainActor
final class LoanApplicationValidationTests: XCTestCase {

    private var mockService: MockLoanService!
    private var viewModel: LoanApplicationViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockLoanService()
        viewModel = LoanApplicationViewModel(loanService: mockService)
    }

    func testAmountBelowMinimumFailsValidation() {
        viewModel.amount = 4999.0
        viewModel.amountString = "4999"
        viewModel.termMonths = 12

        let isValid = viewModel.validateStep1()

        XCTAssertFalse(isValid, "Amount below 5,000 DOP must fail validation")
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("mínimo") == true)
    }

    func testAmountAboveMaximumFailsValidation() {
        viewModel.amount = 100001.0
        viewModel.amountString = "100001"
        viewModel.termMonths = 12

        let isValid = viewModel.validateStep1()

        XCTAssertFalse(isValid, "Amount above 100,000 DOP must fail validation")
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("máximo") == true)
    }

    func testAmountWithinValidRangePasses() {
        let validAmounts = [5000.0, 25000.0, 50000.0, 100000.0]

        for amt in validAmounts {
            viewModel.amount = amt
            viewModel.amountString = String(format: "%.0f", amt)
            viewModel.termMonths = 12

            let isValid = viewModel.validateStep1()
            XCTAssertTrue(isValid, "Amount \(amt) DOP should pass validation")
            XCTAssertNil(viewModel.validationError)
        }
    }

    func testTermBelowMinimumFailsValidation() {
        viewModel.amount = 25000.0
        viewModel.amountString = "25000"
        viewModel.termMonths = 2

        let isValid = viewModel.validateStep1()

        XCTAssertFalse(isValid, "Term below 3 months must fail validation")
        XCTAssertNotNil(viewModel.validationError)
    }

    func testTermAboveMaximumFailsValidation() {
        viewModel.amount = 25000.0
        viewModel.amountString = "25000"
        viewModel.termMonths = 25

        let isValid = viewModel.validateStep1()

        XCTAssertFalse(isValid, "Term above 24 months must fail validation")
        XCTAssertNotNil(viewModel.validationError)
    }

    func testTermWithinValidRangePasses() {
        let validTerms = [3, 6, 12, 18, 24]

        for term in validTerms {
            viewModel.amount = 25000.0
            viewModel.amountString = "25000"
            viewModel.termMonths = term

            let isValid = viewModel.validateStep1()
            XCTAssertTrue(isValid, "Term \(term) months should pass validation")
            XCTAssertNil(viewModel.validationError)
        }
    }

    func testQuickAmountSelectionUpdatesValues() {
        viewModel.setQuickAmount(50000.0)

        XCTAssertEqual(viewModel.amount, 50000.0)
        XCTAssertEqual(viewModel.amountString, "50000")
        XCTAssertNil(viewModel.validationError)
    }

    func testTermsAndConditionsRequiredForSubmission() async {
        viewModel.acceptedTerms = false

        let success = await viewModel.submitLoanApplication()

        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.submissionError, "Debes aceptar los términos y condiciones para continuar.")
    }

    func testIdempotencyKeyIsPreservedAcrossRetries() async {
        viewModel.acceptedTerms = true
        let initialKey = viewModel.idempotencyKey
        XCTAssertFalse(initialKey.isEmpty)

        // First attempt: simulate 500 error
        mockService.shouldSucceed = false
        mockService.errorToThrow = .serverError(message: "500 Intermittent Error")

        let firstAttemptSuccess = await viewModel.submitLoanApplication()
        XCTAssertFalse(firstAttemptSuccess)
        XCTAssertEqual(viewModel.idempotencyKey, initialKey, "Idempotency key must NOT change after a failed attempt")

        // Second attempt: retry after fixing
        mockService.shouldSucceed = true

        let secondAttemptSuccess = await viewModel.submitLoanApplication()
        XCTAssertTrue(secondAttemptSuccess)
        XCTAssertEqual(viewModel.idempotencyKey, initialKey, "Idempotency key must remain identical during retry")

        // Assert that both service calls received the identical idempotency key
        XCTAssertEqual(mockService.createLoanKeysReceived.count, 2)
        XCTAssertEqual(mockService.createLoanKeysReceived[0], initialKey)
        XCTAssertEqual(mockService.createLoanKeysReceived[1], initialKey)
    }
}
