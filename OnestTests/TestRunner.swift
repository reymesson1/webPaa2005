//
//  TestRunner.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

// ANSI terminal colors
private let green = "\u{001B}[0;32m"
private let red = "\u{001B}[0;31m"
private let cyan = "\u{001B}[0;36m"
private let bold = "\u{001B}[1m"
private let reset = "\u{001B}[0m"

@main
struct TestRunner {
    static var totalPassed = 0
    static var totalFailed = 0

    static func main() async {
        print("\n\(bold)\(cyan)=======================================================\(reset)")
        print("\(bold)\(cyan)  ONEST LITE — SUITE DE PRUEBAS UNITARIAS (TEST RUNNER) \(reset)")
        print("\(bold)\(cyan)=======================================================\(reset)\n")

        await runTokenRefreshTests()
        await runLoanValidationTests()
        await runLoansViewModelTests()
        await runLoginViewModelTests()
        await runKeychainTests()

        print("\n\(bold)-------------------------------------------------------\(reset)")
        print("\(bold)Resumen Final:\(reset)")
        print("  \(green)Pasadas: \(totalPassed)\(reset)")
        if totalFailed > 0 {
            print("  \(red)Fallidas: \(totalFailed)\(reset)")
        } else {
            print("  \(red)Fallidas: 0\(reset)")
            print("\n\(bold)\(green)✓ TODAS LAS PRUEBAS UNITARIAS PASARON EXITOSAMENTE!\(reset)\n")
        }
        print("\(bold)\(cyan)=======================================================\(reset)\n")

        if totalFailed > 0 {
            exit(1)
        }
    }

    static func assertTest(_ condition: Bool, _ name: String, file: String = #file, line: Int = #line) {
        if condition {
            totalPassed += 1
            print("  \(green)✓ [PASS]\(reset) \(name)")
        } else {
            totalFailed += 1
            print("  \(red)✗ [FAIL]\(reset) \(name) (linea \(line))")
        }
    }

    // MARK: - 1. Renovación de token con peticiones concurrentes
    static func runTokenRefreshTests() async {
        print("\(bold)1. Pruebas de Renovación Concurrente de Token (Actor & Concurrency):\(reset)")

        SimulatedBackend.shared.resetToInitialState()
        SimulatedBackend.shared.enableRandomLatency = false

        // Test 1: 10 concurrent requests with expired token
        let initialStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "expired_token_123",
                refreshToken: "ref_token_initial_456",
                expiresAt: Date().addingTimeInterval(-10),
                user: User(id: "usr_1", name: "Ricardo Messon", email: "usuario@onest.com")
            )
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SimulatedURLProtocol.self]
        let session = URLSession(configuration: config)

        let coordinator = TokenRefreshCoordinator(tokenStorage: initialStorage, session: session)

        do {
            var tokens: [String] = []
            try await withThrowingTaskGroup(of: String.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        return try await coordinator.getValidAccessToken()
                    }
                }
                for try await token in group {
                    tokens.append(token)
                }
            }

            assertTest(tokens.count == 10, "10 peticiones concurrentes completadas con éxito")
            let firstToken = tokens.first ?? ""
            assertTest(tokens.allSatisfy { $0 == firstToken }, "Todas las 10 peticiones concurrentes reciben el mismo nuevo token")
            assertTest(firstToken != "expired_token_123", "El token recibido es el nuevo token refrescado")

            let count = await coordinator.refreshExecutionCount
            assertTest(count == 1, "Deduplicación atómica: Se ejecutó exactamente 1 llamada de refresh en red para las 10 peticiones")
            assertTest(initialStorage.getAccessToken() == firstToken, "El almacenamiento en Keychain fue actualizado con el nuevo token")
        } catch {
            assertTest(false, "Fallo en peticiones concurrentes: \(error)")
        }

        // Test 2: Expired refresh token forces logout
        let expiredStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "expired",
                refreshToken: "invalid_expired_refresh_token",
                expiresAt: Date().addingTimeInterval(-30),
                user: User(id: "usr_1", name: "Ricardo", email: "ricardo@onest.com")
            )
        )
        let coordinatorExpired = TokenRefreshCoordinator(tokenStorage: expiredStorage, session: session)
        do {
            _ = try await coordinatorExpired.refreshToken()
            assertTest(false, "Refresh token expirado debe fallar con 401")
        } catch let error as APIError {
            assertTest(error == .sessionExpired, "Refresh token expirado lanza APIError.sessionExpired")
            assertTest(expiredStorage.getSession() == nil, "Sesión eliminada de almacenamiento tras refresh expirado")
        } catch {
            assertTest(false, "Error inesperado: \(error)")
        }

        // Test 3: Token still valid does not refresh
        let validStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "valid_token_now",
                refreshToken: "ref_token",
                expiresAt: Date().addingTimeInterval(50),
                user: User(id: "usr_1", name: "Ricardo", email: "ricardo@onest.com")
            )
        )
        let coordinatorValid = TokenRefreshCoordinator(tokenStorage: validStorage, session: session)
        do {
            let tok = try await coordinatorValid.getValidAccessToken()
            assertTest(tok == "valid_token_now", "Token vigente retornado de inmediato sin refresh")
            let count = await coordinatorValid.refreshExecutionCount
            assertTest(count == 0, "No se ejecutó ninguna llamada de refresh para token vigente")
        } catch {
            assertTest(false, "Error con token válido: \(error)")
        }
    }

    // MARK: - 2. Validación del formulario de solicitud
    @MainActor
    static func runLoanValidationTests() async {
        print("\n\(bold)2. Pruebas de Validación del Formulario de Solicitud de Préstamo:\(reset)")

        let mockService = MockLoanService()
        let vm = LoanApplicationViewModel(loanService: mockService)

        // Test Min Amount
        vm.amount = 4999.0
        vm.amountString = "4999"
        vm.termMonths = 12
        assertTest(vm.validateStep1() == false, "Monto < 5,000 DOP falla validación")
        assertTest(vm.validationError?.contains("mínimo") == true, "Mensaje de error especifica monto mínimo")

        // Test Max Amount
        vm.amount = 100001.0
        vm.amountString = "100001"
        assertTest(vm.validateStep1() == false, "Monto > 100,000 DOP falla validación")
        assertTest(vm.validationError?.contains("máximo") == true, "Mensaje de error especifica monto máximo")

        // Test Valid Amounts
        vm.amount = 25000.0
        vm.amountString = "25000"
        assertTest(vm.validateStep1() == true, "Monto válido de 25,000 DOP pasa validación")

        // Test Min Term
        vm.termMonths = 2
        assertTest(vm.validateStep1() == false, "Plazo < 3 meses falla validación")

        // Test Max Term
        vm.termMonths = 25
        assertTest(vm.validateStep1() == false, "Plazo > 24 meses falla validación")

        // Test Valid Term
        vm.termMonths = 6
        assertTest(vm.validateStep1() == true, "Plazo válido de 6 meses pasa validación")

        // Test Quick Amount Selection
        vm.setQuickAmount(50000.0)
        assertTest(vm.amount == 50000.0 && vm.amountString == "50000", "Botón de selección rápida actualiza monto")

        // Test Idempotency Key Preservation across retries
        let originalKey = vm.idempotencyKey
        assertTest(!originalKey.isEmpty, "Generación automática de Idempotency-Key UUID")

        mockService.shouldSucceed = false
        mockService.errorToThrow = .serverError(message: "500 Intermittent")
        vm.acceptedTerms = true

        let firstAttempt = await vm.submitLoanApplication()
        assertTest(firstAttempt == false, "Primer intento falla con error 500 simulado")
        assertTest(vm.idempotencyKey == originalKey, "Idempotency-Key se preserva intacta tras fallo 500")

        mockService.shouldSucceed = true
        let retryAttempt = await vm.submitLoanApplication()
        assertTest(retryAttempt == true, "Reintento con la misma Idempotency-Key es exitoso")
        assertTest(mockService.createLoanKeysReceived.count == 2, "Se enviaron dos llamadas al servicio")
        assertTest(mockService.createLoanKeysReceived[0] == originalKey && mockService.createLoanKeysReceived[1] == originalKey, "Ambas llamadas enviaron la misma Idempotency-Key")
    }

    // MARK: - 3. ViewModel: LoansViewModel
    @MainActor
    static func runLoansViewModelTests() async {
        print("\n\(bold)3. Pruebas Unitarias de ViewModel (LoansViewModel):\(reset)")

        let mockService = MockLoanService()
        mockService.mockLoans = [
            Loan(id: "L1", amount: 50000, remainingBalance: 30000, nextPaymentDate: Date(), status: .desembolsado, termMonths: 12, interestRate: 0.18, monthlyPayment: 4500, totalCost: 54000, createdAt: Date()),
            Loan(id: "L2", amount: 25000, remainingBalance: 25000, nextPaymentDate: Date(), status: .aprobado, termMonths: 6, interestRate: 0.18, monthlyPayment: 4300, totalCost: 25800, createdAt: Date()),
            Loan(id: "L3", amount: 15000, remainingBalance: 0, nextPaymentDate: nil, status: .pagado, termMonths: 6, interestRate: 0.18, monthlyPayment: 2600, totalCost: 15600, createdAt: Date())
        ]

        let vm = LoansViewModel(loanService: mockService)
        assertTest(vm.loans.isEmpty, "Estado inicial de lista de préstamos vacío")

        await vm.fetchLoans()
        assertTest(vm.loans.count == 3, "fetchLoans() carga los 3 préstamos correctamente")
        assertTest(vm.isLoading == false, "isLoading pasa a false al terminar")
        assertTest(vm.totalBalancePending == 30000, "Cálculo de balance pendiente suma préstamos desembolsados (30,000 DOP)")
        assertTest(vm.activeLoansCount == 2, "Cálculo de préstamos activos (Desembolsado + Aprobado = 2)")

        // Status filtering
        vm.selectFilter(.pagado)
        assertTest(vm.filteredLoans.count == 1 && vm.filteredLoans.first?.id == "L3", "Filtro por estado PAGADO funciona")

        vm.selectFilter(.pagado) // toggle off
        assertTest(vm.filteredLoans.count == 3, "Desactivar filtro restablece todos los préstamos")
    }

    // MARK: - 4. ViewModel: LoginViewModel
    @MainActor
    static func runLoginViewModelTests() async {
        print("\n\(bold)4. Pruebas Unitarias de ViewModel (LoginViewModel):\(reset)")

        let mockAuth = MockAuthService()
        let vm = LoginViewModel(authService: mockAuth)

        vm.username = ""
        vm.password = ""
        assertTest(vm.validate() == false, "Validación falla con credenciales vacías")
        assertTest(vm.usernameError != nil && vm.passwordError != nil, "Errores individuales asignados a usuario y clave")

        vm.username = "usuario@onest.com"
        vm.password = "12"
        assertTest(vm.validate() == false, "Validación falla con contraseña menor a 4 caracteres")

        vm.password = "123456"
        assertTest(vm.validate() == true, "Validación exitosa con credenciales completas")

        mockAuth.shouldSucceed = true
        let success = await vm.login()
        assertTest(success == true, "Login exitoso autentica y retorna true")
        assertTest(mockAuth.loginCallCount == 1, "Servicio de autenticación invocado una vez")

        mockAuth.shouldSucceed = false
        mockAuth.errorToThrow = .unauthorized(message: "Credenciales inválidas.")
        let failure = await vm.login()
        assertTest(failure == false, "Login con credenciales incorrectas retorna false")
        assertTest(vm.errorMessage == "Credenciales inválidas.", "Mensaje de error 401 reflejado en ViewModel")
    }

    // MARK: - 5. Keychain & Persistencia
    static func runKeychainTests() async {
        print("\n\(bold)5. Pruebas de Persistencia en Keychain (Security Framework):\(reset)")

        let keychain = KeychainManager(service: "com.onest.lite.test.\(UUID().uuidString)")
        let session = UserSession(
            accessToken: "keychain_access_token_1",
            refreshToken: "keychain_refresh_token_1",
            expiresAt: Date().addingTimeInterval(3600),
            user: User(id: "usr_99", name: "Ricardo Messon", email: "ricardo@onest.com")
        )

        do {
            try keychain.saveSession(session)
            let retrieved = keychain.getSession()
            assertTest(retrieved != nil, "Sesión guardada en Keychain exitosamente")
            assertTest(retrieved?.accessToken == "keychain_access_token_1", "Access token recuperado del Keychain")
            assertTest(retrieved?.user.name == "Ricardo Messon", "Datos de usuario recuperados del Keychain")

            try keychain.updateTokens(accessToken: "new_access_2", refreshToken: "new_refresh_2", expiresIn: 60)
            let updated = keychain.getSession()
            assertTest(updated?.accessToken == "new_access_2", "Tokens actualizados en Keychain tras renovación")

            try keychain.clearSession()
            assertTest(keychain.getSession() == nil, "Cerrar sesión elimina todas las credenciales del dispositivo")
            assertTest(keychain.getAccessToken() == nil, "Access token eliminado por completo")
        } catch {
            assertTest(false, "Error en operaciones de Keychain: \(error)")
        }
    }
}
