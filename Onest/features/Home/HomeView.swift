//
//  HomeView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0
    @State private var showingLogoutAlert: Bool = false
    @State private var isPresentingNewLoan: Bool = false
    @State private var isShowingProfile: Bool = false

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
        ZStack {
            if isShowingProfile {
                // Profile & Reviewer Screen (TabView is completely hidden)
                VStack(spacing: 0) {
                    // Profile Header with Left Arrow to go back
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isShowingProfile = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Volver")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(OnestTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }

                        Spacer()

                        Text("Mi Cuenta")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(OnestTheme.textPrimary)

                        Spacer()

                        Button {
                            showingLogoutAlert = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 229/255, green: 57/255, blue: 53/255))
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(OnestTheme.cardBackground)

                    reviewerAndProfileView
                }
                .background(OnestTheme.background.ignoresSafeArea())
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                // Main App Flow with Always-Visible Avatar at Top-Left & TabView
                VStack(spacing: 0) {
                    topHeaderBar

                    TabView(selection: $selectedTab) {
                        // 1. HomeView with text in the center saying HomeView and Home icon
                        homeTabContentView
                            .tabItem {
                                Label("Inicio", systemImage: "house.fill")
                            }
                            .tag(0)

                        // 2. Billetera ('wallet') and its icon
                        walletTabContentView
                            .tabItem {
                                Label("Billetera", systemImage: "wallet.pass.fill")
                            }
                            .tag(1)

                        // 3. '+' around circle with brand color
                        newLoanPromptContentView
                            .tabItem {
                                Label("Solicitar", systemImage: "plus.circle.fill")
                            }
                            .tag(2)

                        // 4. Mis Préstamos view and its icon
                        LoansListView()
                            .tabItem {
                                Label("Mis Préstamos", systemImage: "banknote.fill")
                            }
                            .tag(3)

                        // 5. Premios and its color 'trofeum' icon
                        rewardsTabContentView
                            .tabItem {
                                Label("Premios", systemImage: "trophy.fill")
                            }
                            .tag(4)
                    }
                    .tint(OnestTheme.primary)
                    .onChange(of: selectedTab) { newTab in
                        if newTab == 2 {
                            isPresentingNewLoan = true
                            selectedTab = previousTab
                        } else {
                            previousTab = newTab
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingNewLoan) {
            LoanApplicationFlowView {
                selectedTab = 3 // Switch to "Mis Préstamos" tab to see newly created loan
            }
        }
        .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                try? authService.logout()
            }
        } message: {
            Text("Se eliminarán de forma segura todos los tokens y credenciales guardados en el Keychain de este dispositivo.")
        }
    }

    // MARK: - Persistent Top Header Bar with Avatar in Top Left
    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isShowingProfile = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [OnestTheme.mintGreen, OnestTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: OnestTheme.mintGreen.opacity(0.35), radius: 4, x: 0, y: 2)

                    Text(userInitials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hola, \(currentUser?.name.components(separatedBy: " ").first ?? "Ricardo")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)
                Text("Toca tu avatar para ver perfil")
                    .font(.system(size: 10))
                    .foregroundColor(OnestTheme.textSecondary)
            }

            Spacer()

            // Small Brand Logo in Header
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("ON")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(OnestTheme.limeAccent)
                            .frame(height: 2.5)
                            .offset(y: 4)
                    }
                Text("EST")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(OnestTheme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(OnestTheme.cardBackground)
    }

    // MARK: - Tab 1: HomeView (Text in the center saying HomeView)
    private var homeTabContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Centered "HomeView" Text as requested
                VStack(spacing: 8) {
                    Text("HomeView")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(OnestTheme.textPrimary)

                    Text("Bienvenido a Onest Lite")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(OnestTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .padding(.bottom, 16)

                // Quick Credit Balance Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tu Crédito Disponible")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(OnestTheme.textSecondary)
                            Text("RD$ 70,000.00")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(OnestTheme.primary)
                        }
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(OnestTheme.limeAccent)
                    }

                    Divider()

                    HStack {
                        Text("Límite pre-aprobado hasta RD$ 100,000")
                            .font(.system(size: 12))
                            .foregroundColor(OnestTheme.textSecondary)
                        Spacer()
                        Button("Solicitar") {
                            isPresentingNewLoan = true
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnestTheme.primary)
                    }
                }
                .padding(18)
                .background(OnestTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 16)

                // Action Banner
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("¿Necesitas financiamiento?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Solicita en 3 pasos con cuota fija y tasa preferencial.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))

                        Button {
                            isPresentingNewLoan = true
                        } label: {
                            Text("Solicitar Préstamo")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(OnestTheme.primaryDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [OnestTheme.mintGreen, OnestTheme.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: OnestTheme.mintGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
            }
        }
        .background(OnestTheme.appBackgroundGradient.ignoresSafeArea())
    }

    // MARK: - Tab 2: Billetera ('wallet')
    private var walletTabContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Wallet Balance Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Saldo en Billetera")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    Text("RD$ 14,850.00")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Label("Cuenta Onest", systemImage: "checkmark.shield.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("DOP")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                    }
                }
                .padding(22)
                .background(
                    LinearGradient(
                        colors: [OnestTheme.primaryDark, Color(red: 40/255, green: 50/255, blue: 60/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Quick Actions
                HStack(spacing: 14) {
                    walletActionButton(title: "Transferir", icon: "arrow.up.right")
                    walletActionButton(title: "Pagar Cuota", icon: "creditcard")
                    walletActionButton(title: "Recargar", icon: "plus")
                }
                .padding(.horizontal, 16)

                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Movimientos Recientes")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OnestTheme.textPrimary)
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        walletMovementRow(
                            title: "Desembolso Préstamo",
                            subtitle: "Acreditado en cuenta",
                            amount: "+ RD$ 25,000.00",
                            isCredit: true,
                            date: "01 Oct 2026"
                        )
                        walletMovementRow(
                            title: "Pago de Cuota #1",
                            subtitle: "Préstamo LOAN-1001",
                            amount: "- RD$ 4,386.42",
                            isCredit: false,
                            date: "28 Sep 2026"
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
            }
        }
        .background(OnestTheme.appBackgroundGradient.ignoresSafeArea())
    }

    private func walletActionButton(title: String, icon: String) -> some View {
        Button {
            // Informative action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(OnestTheme.primary)
                    .frame(width: 44, height: 44)
                    .background(OnestTheme.primaryLight)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OnestTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(OnestTheme.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }

    private func walletMovementRow(title: String, subtitle: String, amount: String, isCredit: Bool, date: String) -> some View {
        HStack {
            Image(systemName: isCredit ? "arrow.down.left" : "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isCredit ? OnestTheme.primary : Color(red: 220/255, green: 38/255, blue: 38/255))
                .frame(width: 36, height: 36)
                .background(isCredit ? OnestTheme.primaryLight : Color(red: 254/255, green: 242/255, blue: 242/255))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OnestTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(OnestTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isCredit ? OnestTheme.primary : OnestTheme.textPrimary)
                Text(date)
                    .font(.system(size: 11))
                    .foregroundColor(OnestTheme.textSecondary)
            }
        }
        .padding(14)
        .background(OnestTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    // MARK: - Tab 3: Fallback Prompt for '+' Tab
    private var newLoanPromptContentView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(OnestTheme.primaryLight)
                    .frame(width: 90, height: 90)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(OnestTheme.primary)
            }

            VStack(spacing: 8) {
                Text("Solicitar Nuevo Préstamo")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(OnestTheme.textPrimary)

                Text("Calcula tu cuota en tiempo real y recibe aprobación inmediata de 5,000 a 100,000 DOP.")
                    .font(.system(size: 14))
                    .foregroundColor(OnestTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            OnestButton(
                title: "Iniciar Solicitud",
                icon: "sparkles",
                style: .primary
            ) {
                isPresentingNewLoan = true
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OnestTheme.appBackgroundGradient.ignoresSafeArea())
    }

    // MARK: - Tab 5: Premios ('trofeum')
    private var rewardsTabContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Trophy Banner
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 54))
                        .foregroundColor(OnestTheme.limeAccent)
                        .shadow(color: OnestTheme.limeAccent.opacity(0.4), radius: 8, x: 0, y: 4)

                    Text("Club de Premios Onest")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Puntos acumulados por pagos puntuales")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))

                    HStack(spacing: 6) {
                        Text("1,250")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Puntos")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(OnestTheme.limeAccent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [OnestTheme.mintGreen, OnestTheme.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .shadow(color: OnestTheme.mintGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Reward Badges
                VStack(alignment: .leading, spacing: 14) {
                    Text("Logros Desbloqueados")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OnestTheme.textPrimary)

                    rewardBadgeRow(
                        title: "Buen Pagador Nivel 1",
                        description: "Pagaste tu primera cuota a tiempo",
                        icon: "medal.fill",
                        color: Color(red: 245/255, green: 158/255, blue: 11/255)
                    )
                    rewardBadgeRow(
                        title: "Tasa Preferencial",
                        description: "Descuento de 2% en tu próxima solicitud",
                        icon: "percent",
                        color: OnestTheme.primary
                    )
                    rewardBadgeRow(
                        title: "Perfil Verificado",
                        description: "Identidad y cuenta validadas con éxito",
                        icon: "checkmark.seal.fill",
                        color: Color(red: 59/255, green: 130/255, blue: 246/255)
                    )
                }
                .padding(18)
                .background(OnestTheme.cardBackground)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 16)
            }
        }
        .background(OnestTheme.appBackgroundGradient.ignoresSafeArea())
    }

    private func rewardBadgeRow(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OnestTheme.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(OnestTheme.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Reviewer & Profile View (Full Screen when avatar tapped)
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

                        Text(currentUser?.email ?? "reymesson@gmail.com")
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
        guard let name = currentUser?.name, !name.isEmpty else { return "RM" }
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
