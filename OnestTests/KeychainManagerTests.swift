//
//  KeychainManagerTests.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

#if canImport(Onest)
@testable import Onest
#endif

final class KeychainManagerTests: XCTestCase {

    private var keychain: KeychainManager!

    override func setUp() {
        super.setUp()
        // Use test-specific service name to isolate keychain
        keychain = KeychainManager(service: "com.onest.lite.test.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? keychain.clearSession()
        super.tearDown()
    }

    func testSaveAndRetrieveSession() throws {
        let user = User(id: "usr_test", name: "Maria Sanchez", email: "maria@onest.com")
        let session = UserSession(
            accessToken: "access_123",
            refreshToken: "refresh_456",
            expiresAt: Date().addingTimeInterval(3600),
            user: user
        )

        try keychain.saveSession(session)

        let retrieved = keychain.getSession()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.accessToken, "access_123")
        XCTAssertEqual(retrieved?.refreshToken, "refresh_456")
        XCTAssertEqual(retrieved?.user.name, "Maria Sanchez")
        XCTAssertEqual(keychain.getAccessToken(), "access_123")
        XCTAssertEqual(keychain.getRefreshToken(), "refresh_456")
    }

    func testUpdateTokens() throws {
        let user = User(id: "usr_test", name: "Maria Sanchez", email: "maria@onest.com")
        let session = UserSession(
            accessToken: "old_access",
            refreshToken: "old_refresh",
            expiresAt: Date().addingTimeInterval(60),
            user: user
        )

        try keychain.saveSession(session)
        try keychain.updateTokens(accessToken: "new_access", refreshToken: "new_refresh", expiresIn: 120)

        let updated = keychain.getSession()
        XCTAssertEqual(updated?.accessToken, "new_access")
        XCTAssertEqual(updated?.refreshToken, "new_refresh")
        XCTAssertEqual(updated?.user.name, "Maria Sanchez")
    }

    func testClearSessionRemovesCredentials() throws {
        let user = User(id: "usr_test", name: "Maria Sanchez", email: "maria@onest.com")
        let session = UserSession(
            accessToken: "access_123",
            refreshToken: "refresh_456",
            expiresAt: Date().addingTimeInterval(60),
            user: user
        )

        try keychain.saveSession(session)
        XCTAssertNotNil(keychain.getSession())

        try keychain.clearSession()
        XCTAssertNil(keychain.getSession(), "Session should be completely wiped from device upon logout")
        XCTAssertNil(keychain.getAccessToken())
        XCTAssertNil(keychain.getRefreshToken())
    }
}
