//
//  AuthModels.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public struct User: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

public struct LoginRequest: Codable, Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct AuthResponse: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: TimeInterval
    public let tokenType: String
    public let user: User

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: TimeInterval = 60,
        tokenType: String = "Bearer",
        user: User
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.user = user
    }
}

public struct TokenRefreshRequest: Codable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct TokenRefreshResponse: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: TimeInterval
    public let tokenType: String

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: TimeInterval = 60,
        tokenType: String = "Bearer"
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}

public struct UserSession: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let user: User

    public var isExpired: Bool {
        return Date() >= expiresAt
    }

    public var isNearExpiry: Bool {
        // Considered near expiry if less than 5 seconds remaining
        return Date().addingTimeInterval(5) >= expiresAt
    }

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        user: User
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
}
