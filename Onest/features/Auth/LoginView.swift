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
        ZStack {
            // Background soft vertical gradient
            OnestTheme.appBackgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top Logo
                    logoView
                        .padding(.top, 60)

                    // Heading
                    VStack(spacing: 4) {
                        Text("Ingresa tu correo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(OnestTheme.textPrimary)

                        (Text("para ")
                            .foregroundColor(OnestTheme.textPrimary)
                         + Text("Iniciar Sesión")
                            .foregroundColor(OnestTheme.mintGreen))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 36)

                    // Error Banner if any
                    if let errorMsg = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(red: 220/255, green: 38/255, blue: 38/255))
                                .font(.system(size: 16))

                            Text(errorMsg)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 185/255, green: 28/255, blue: 28/255))

                            Spacer()
                        }
                        .padding(14)
                        .background(Color(red: 254/255, green: 242/255, blue: 242/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 252/255, green: 165/255, blue: 165/255), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Form Fields
                    VStack(spacing: 18) {
                        // Email Field with notched label
                        OnestTextField(
                            label: "Correo",
                            placeholder: "reymesson@gmail.com",
                            icon: "envelope",
                            text: $viewModel.username,
                            errorMessage: viewModel.usernameError,
                            keyboardType: .emailAddress
                        )

                        // Password Field
                        OnestTextField(
                            label: nil,
                            placeholder: "Contraseña",
                            icon: "lock",
                            isSecure: true,
                            text: $viewModel.password,
                            errorMessage: viewModel.passwordError
                        )

                        // Iniciar sesión button
                        OnestButton(
                            title: "Iniciar sesión",
                            style: .neutral,
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
                        .padding(.top, 4)

                        // Forgot password link
                        Button {
                            // Informative action
                        } label: {
                            Text("¿Olvidaste tu contraseña?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(OnestTheme.linkColor)
                                .underline()
                        }
                        .padding(.top, 14)
                    }
                    .padding(.horizontal, 24)

                    // Reviewer Quick Fill Helpers
                    VStack(alignment: .center, spacing: 8) {
                        Text("Accesos de prueba para el evaluador:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(OnestTheme.textSecondary)

                        HStack(spacing: 8) {
                            Button {
                                viewModel.username = "reymesson@gmail.com"
                                viewModel.password = "123456"
                                viewModel.errorMessage = nil
                            } label: {
                                Text("Válidas (200)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white)
                                    .foregroundColor(OnestTheme.primary)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(OnestTheme.mintGreen, lineWidth: 1)
                                    )
                            }

                            Button {
                                viewModel.username = "invalido@onest.com"
                                viewModel.password = "invalid"
                                viewModel.errorMessage = nil
                            } label: {
                                Text("Inválidas (401)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white)
                                    .foregroundColor(Color.red)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.top, 44)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var logoView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("ON")
                .font(.system(size: 34, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(OnestTheme.textPrimary)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(OnestTheme.limeAccent)
                        .frame(height: 4)
                        .offset(y: 8)
                }

            Text("EST")
                .font(.system(size: 34, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(OnestTheme.textPrimary)
        }
    }
}
