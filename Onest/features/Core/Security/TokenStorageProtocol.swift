//
//  TokenStorageProtocol.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public protocol TokenStorageProtocol: AnyObject, Sendable {
    func saveSession(_ session: UserSession) throws
    func getSession() -> UserSession?
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func updateTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) throws
    func clearSession() throws
}
