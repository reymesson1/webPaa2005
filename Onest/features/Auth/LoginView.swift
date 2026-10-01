//
//  LoginView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    public let onLoginSuccess: () -> Void

    public init(
        authService: AuthServiceProtocol = AuthService.shared,
        onLoginSuccess: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
        self.onLoginSuccess = onLoginSuccess
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header / Branding
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(OnestTheme.primaryLight)
                            .frame(width: 84, height: 84)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(OnestTheme.primary)
                    }
                    .padding(.top, 40)

                    Text("Onest Lite")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(OnestTheme.textPrimary)

                    Text("Tu crédito transparente y al instante")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                }

                // Error Banner
                if let errorMsg = viewModel.errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(Color(red: 229/255, green: 57/255, blue: 53/255))
                            .font(.system(size: 18))

                        Text(errorMsg)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))

                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 255/255, green: 235/255, blue: 238/255))
                    .cornerRadius(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Inputs Card
                VStack(spacing: 20) {
                    OnestTextField(
                        label: "Usuario o Correo",
                        placeholder: "ejemplo@onest.com",
                        icon: "person.crop.circle.fill",
                        text: $viewModel.username,
                        errorMessage: viewModel.usernameError,
                        keyboardType: .emailAddress
                    )

                    OnestTextField(
                        label: "Contraseña",
                        placeholder: "••••••••",
                        icon: "lock.fill",
                        isSecure: true,
                        text: $viewModel.password,
                        errorMessage: viewModel.passwordError
                    )

                    OnestButton(
                        title: "Iniciar Sesión",
                        icon: "arrow.right.circle.fill",
                        style: .primary,
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.isFormValid
                    ) {
                        Task {
                            let success = await viewModel.login()
                            if success {
                                onLoginSuccess()
                            }
                        }
                    }
                }
                .padding(20)
                .background(OnestTheme.cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)

                // Reviewer Quick Fill Helper Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Accesos de prueba rápida:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnestTheme.textSecondary)

                    HStack(spacing: 10) {
                        Button {
                            viewModel.username = "usuario@onest.com"
                            viewModel.password = "123456"
                            viewModel.errorMessage = nil
                        } label: {
                            Text("Credenciales válidas (200)")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(OnestTheme.primaryLight)
                                .foregroundColor(OnestTheme.primaryDark)
                                .cornerRadius(8)
                        }

                        Button {
                            viewModel.username = "invalido@onest.com"
                            viewModel.password = "invalid"
                            viewModel.errorMessage = nil
                        } label: {
                            Text("Credenciales inválidas (401)")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(red: 255/255, green: 235/255, blue: 238/255))
                                .foregroundColor(Color(red: 198/255, green: 40/255, blue: 40/255))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(OnestTheme.background.ignoresSafeArea())
    }
}
