//
//  AuthService.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public protocol AuthServiceProtocol: Sendable {
    func login(username: String, password: String) async throws -> UserSession
    func logout() throws
    func getCurrentSession() -> UserSession?
    var isAuthenticated: Bool { get }
}

public final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    public static let shared = AuthService()

    private let apiClient: APIClientProtocol
    private let tokenStorage: TokenStorageProtocol

    public init(
        apiClient: APIClientProtocol = APIClient.shared,
        tokenStorage: TokenStorageProtocol = KeychainManager.shared
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
    }

    public var isAuthenticated: Bool {
        return tokenStorage.getSession() != nil
    }

    public func getCurrentSession() -> UserSession? {
        return tokenStorage.getSession()
    }

    public func login(username: String, password: String) async throws -> UserSession {
        let request = LoginRequest(username: username, password: password)
        let endpoint = APIEndpoint.login(request)
        let authResponse: AuthResponse = try await apiClient.request(endpoint)

        let session = UserSession(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: Date().addingTimeInterval(authResponse.expiresIn),
            user: authResponse.user
        )

        try tokenStorage.saveSession(session)
        return session
    }

    public func logout() throws {
        try tokenStorage.clearSession()
        Task { @MainActor in
            NotificationCenter.default.post(name: .sessionDidExpire, object: nil)
        }
    }
}
