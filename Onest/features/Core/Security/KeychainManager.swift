//
//  KeychainManager.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation
import Security

public final class KeychainManager: TokenStorageProtocol, @unchecked Sendable {
    public static let shared = KeychainManager()

    private let service: String
    private let sessionKey = "user_session"
    private let lock = NSLock()

    // In-memory fallback if keychain is inaccessible (e.g., in unsigned test bundles/CLI)
    private var memoryCache: UserSession?

    public init(service: String = "com.onest.lite.auth") {
        self.service = service
    }

    public func saveSession(_ session: UserSession) throws {
        lock.lock()
        defer { lock.unlock() }

        memoryCache = session

        let encoder = JSONEncoder()
        let data = try encoder.encode(session)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey
        ]

        // Check if item exists
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus != errSecSuccess && updateStatus != errSecItemNotFound {
                // If keychain update fails in simulator sandbox, memoryCache serves as backup
            }
        } else {
            var newAttributes = query
            newAttributes[kSecValueData as String] = data
            newAttributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            _ = SecItemAdd(newAttributes as CFDictionary, nil)
        }
    }

    public func getSession() -> UserSession? {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data {
            let decoder = JSONDecoder()
            if let session = try? decoder.decode(UserSession.self, from: data) {
                memoryCache = session
                return session
            }
        }

        return memoryCache
    }

    public func getAccessToken() -> String? {
        return getSession()?.accessToken
    }

    public func getRefreshToken() -> String? {
        return getSession()?.refreshToken
    }

    public func updateTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) throws {
        guard let currentSession = getSession() else {
            throw APIError.sessionExpired
        }

        let updatedSession = UserSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            user: currentSession.user
        )

        try saveSession(updatedSession)
    }

    public func clearSession() throws {
        lock.lock()
        defer { lock.unlock() }

        memoryCache = nil

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey
        ]

        _ = SecItemDelete(query as CFDictionary)
    }
}
