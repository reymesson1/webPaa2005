//
//  LoginViewModel.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation
import Combine

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var username: String = "reymesson@gmail.com"
    @Published public var password: String = "123456"
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var usernameError: String? = nil
    @Published public var passwordError: String? = nil

    private let authService: AuthServiceProtocol

    public init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }

    public var isFormValid: Bool {
        return !username.trimmingCharacters(in: .whitespaces).isEmpty &&
               !password.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public func validate() -> Bool {
        usernameError = nil
        passwordError = nil
        errorMessage = nil

        let trimmedUser = username.trimmingCharacters(in: .whitespaces)
        let trimmedPass = password.trimmingCharacters(in: .whitespaces)

        var isValid = true

        if trimmedUser.isEmpty {
            usernameError = "Por favor ingresa tu usuario o correo electrónico."
            isValid = false
        }

        if trimmedPass.isEmpty {
            passwordError = "Por favor ingresa tu contraseña."
            isValid = false
        } else if trimmedPass.count < 4 {
            passwordError = "La contraseña debe tener al menos 4 caracteres."
            isValid = false
        }

        return isValid
    }

    public func login() async -> Bool {
        guard validate() else { return false }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.login(username: username, password: password)
            isLoading = false
            return true
        } catch let error as APIError {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        } catch {
            isLoading = false
            errorMessage = "No se pudo conectar con el servidor. Verifica tu conexión."
            return false
        }
    }
}
