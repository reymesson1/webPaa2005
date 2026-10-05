//
//  TokenRefreshCoordinator.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public extension Notification.Name {
    static let sessionDidExpire = Notification.Name("com.onest.lite.sessionDidExpire")
}

public actor TokenRefreshCoordinator {
    private let tokenStorage: TokenStorageProtocol
    private let session: URLSession

    // In-flight refresh task deduplication
    private var inFlightRefreshTask: Task<String, Error>?

    // Public counter for testing verification
    public private(set) var refreshExecutionCount: Int = 0

    public init(tokenStorage: TokenStorageProtocol, session: URLSession) {
        self.tokenStorage = tokenStorage
        self.session = session
    }

    public func getValidAccessToken() async throws -> String {
        guard let currentSession = tokenStorage.getSession() else {
            throw APIError.sessionExpired
        }

        // If access token is still valid (with at least 5s buffer), return it immediately
        if !currentSession.isNearExpiry {
            return currentSession.accessToken
        }

        // Token is expired or near expiry -> refresh
        return try await refreshToken()
    }

    public func refreshToken() async throws -> String {
        // If a refresh is already in-flight, await and share its result
        if let existingTask = inFlightRefreshTask {
            return try await existingTask.value
        }

        let task = Task<String, Error> { [weak self, tokenStorage, session] () -> String in
            defer {
                Task { [weak self] in
                    await self?.clearInFlightTask()
                }
            }

            guard let refreshToken = tokenStorage.getRefreshToken() else {
                try? tokenStorage.clearSession()
                await MainActor.run {
                    NotificationCenter.default.post(name: .sessionDidExpire, object: nil)
                }
                throw APIError.sessionExpired
            }

            let endpoint = APIEndpoint.refresh(TokenRefreshRequest(refreshToken: refreshToken))
            let request = try endpoint.buildRequest()

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Respuesta de red no válida.")
            }

            if httpResponse.statusCode == 200 {
                let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
                try tokenStorage.updateTokens(
                    accessToken: refreshResponse.accessToken,
                    refreshToken: refreshResponse.refreshToken,
                    expiresIn: refreshResponse.expiresIn
                )
                return refreshResponse.accessToken
            } else if httpResponse.statusCode == 401 {
                // Refresh token expired -> force logout
                try? tokenStorage.clearSession()
                await MainActor.run {
                    NotificationCenter.default.post(name: .sessionDidExpire, object: nil)
                }
                throw APIError.sessionExpired
            } else {
                throw APIError.serverError(message: "Error al refrescar el token (\(httpResponse.statusCode))")
            }
        }

        inFlightRefreshTask = task
        refreshExecutionCount += 1

        do {
            let newToken = try await task.value
            return newToken
        } catch {
            throw error
        }
    }

    private func clearInFlightTask() {
        inFlightRefreshTask = nil
    }

    public func resetExecutionCount() {
        refreshExecutionCount = 0
    }
}
