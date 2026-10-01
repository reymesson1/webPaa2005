//
//  HomeView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var showingLogoutAlert: Bool = false
    @State private var isPresentingNewLoan: Bool = false

    private let authService: AuthServiceProtocol
    private let tokenStorage: TokenStorageProtocol
    private let backend = SimulatedBackend.shared

    public init(
        authService: AuthServiceProtocol = AuthService.shared,
        tokenStorage: TokenStorageProtocol = KeychainManager.shared
    ) {
        self.authService = authService
        self.tokenStorage = tokenStorage
    }

    private var currentUser: User? {
        return tokenStorage.getSession()?.user
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Mis Préstamos
            LoansListView()
                .tabItem {
                    Label("Préstamos", systemImage: "banknote.fill")
                }
                .tag(0)

            // Tab 2: Configuración / Perfil / Evaluador
            NavigationStack {
                reviewerAndProfileView
                    .navigationTitle("Mi Cuenta")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingLogoutAlert = true
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(Color(red: 229/255, green: 57/255, blue: 53/255))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Cuenta", systemImage: "person.crop.circle.fill")
            }
            .tag(1)
        }
        .tint(OnestTheme.primary)
        .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                try? authService.logout()
            }
        } message: {
            Text("Se eliminarán de forma segura todos los tokens y credenciales guardados en el Keychain de este dispositivo.")
        }
    }

    private var reviewerAndProfileView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Profile Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(OnestTheme.primaryLight)
                            .frame(width: 76, height: 76)

                        Text(userInitials)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(OnestTheme.primary)
                    }

                    VStack(spacing: 4) {
                        Text(currentUser?.name ?? "Ricardo Messon")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(OnestTheme.textPrimary)

                        Text(currentUser?.email ?? "usuario@onest.com")
                            .font(.system(size: 14))
                            .foregroundColor(OnestTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(OnestTheme.cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

                // Session Security Info (Keychain)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(OnestTheme.primary)
                        Text("Seguridad de Sesión (Keychain)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(OnestTheme.textPrimary)
                    }

                    VStack(spacing: 10) {
                        infoRow(
                            label: "Almacenamiento",
                            value: "Apple Keychain (kSecClassGenericPassword)"
                        )
                        infoRow(
                            label: "Expiración Access Token",
                            value: "60 segundos (renovación automática)"
                        )
                        infoRow(
                            label: "Persistencia",
                            value: "Activa al reiniciar la app"
                        )
                    }
                }
                .padding(18)
                .background(OnestTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

                // Reviewer Sandbox Controls (Live Testing Tool for Interview)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(OnestTheme.primary)
                        Text("Herramientas para el Revisor")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(OnestTheme.textPrimary)
                    }

                    Text("Controles en vivo para probar todos los escenarios obligatorios descritos en la prueba técnica:")
                        .font(.system(size: 13))
                        .foregroundColor(OnestTheme.textSecondary)

                    Divider()

                    Toggle("Simular latencia (0.5s - 2.0s en /loans)", isOn: Binding(
                        get: { backend.enableRandomLatency },
                        set: { backend.enableRandomLatency = $0 }
                    ))
                    .tint(OnestTheme.primary)
                    .font(.system(size: 14, weight: .medium))

                    Divider()

                    Toggle("Simular Refresh Token Expirado (401)", isOn: Binding(
                        get: { backend.simulateExpiredRefreshToken },
                        set: { backend.simulateExpiredRefreshToken = $0 }
                    ))
                    .tint(Color.orange)
                    .font(.system(size: 14, weight: .medium))

                    Divider()

                    Button {
                        // Trigger immediate token refresh test
                        Task {
                            _ = try? await APIClient.shared.refreshCoordinator.refreshToken()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Forzar Renovación Concurrente de Token")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnestTheme.primary)
                    }

                    Divider()

                    Button {
                        backend.resetToInitialState()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restablecer estado del servidor simulado")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnestTheme.textSecondary)
                    }
                }
                .padding(18)
                .background(OnestTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

                // Logout Action Card
                OnestButton(
                    title: "Cerrar Sesión",
                    icon: "rectangle.portrait.and.arrow.right",
                    style: .destructive
                ) {
                    showingLogoutAlert = true
                }
                .padding(.top, 8)

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(OnestTheme.background.ignoresSafeArea())
    }

    private var userInitials: String {
        guard let name = currentUser?.name, !name.isEmpty else { return "ON" }
        let comps = name.components(separatedBy: " ")
        if comps.count > 1, let f = comps.first?.first, let l = comps.last?.first {
            return "\(f)\(l)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(OnestTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OnestTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
