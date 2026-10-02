//
//  LoginViewModelTests.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

#if canImport(Onest)
@testable import Onest
#endif

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var mockAuthService: MockAuthService!
    private var viewModel: LoginViewModel!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = LoginViewModel(authService: mockAuthService)
    }

    func testValidationFailsWithEmptyFields() {
        viewModel.username = ""
        viewModel.password = ""

        let isValid = viewModel.validate()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(viewModel.usernameError)
        XCTAssertNotNil(viewModel.passwordError)
    }

    func testValidationFailsWithShortPassword() {
        viewModel.username = "usuario@onest.com"
        viewModel.password = "12"

        let isValid = viewModel.validate()

        XCTAssertFalse(isValid)
        XCTAssertNil(viewModel.usernameError)
        XCTAssertEqual(viewModel.passwordError, "La contraseña debe tener al menos 4 caracteres.")
    }

    func testValidationPassesWithValidInputs() {
        viewModel.username = "usuario@onest.com"
        viewModel.password = "123456"

        let isValid = viewModel.validate()

        XCTAssertTrue(isValid)
        XCTAssertNil(viewModel.usernameError)
        XCTAssertNil(viewModel.passwordError)
    }

    func testSuccessfulLogin() async {
        viewModel.username = "usuario@onest.com"
        viewModel.password = "123456"
        mockAuthService.shouldSucceed = true

        let success = await viewModel.login()

        XCTAssertTrue(success)
        XCTAssertEqual(mockAuthService.loginCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFailedLoginSetsErrorMessage() async {
        viewModel.username = "invalido@onest.com"
        viewModel.password = "erronea"
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = .unauthorized(message: "Credenciales inválidas.")

        let success = await viewModel.login()

        XCTAssertFalse(success)
        XCTAssertEqual(mockAuthService.loginCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Credenciales inválidas.")
    }
}
