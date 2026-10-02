//
//  TokenRefreshTests.swift
//  OnestTests
//
//  Created by Ricardo Messon on 10/1/26.
//

#if canImport(Onest)
@testable import Onest
#endif

final class TokenRefreshTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SimulatedBackend.shared.resetToInitialState()
        SimulatedBackend.shared.enableRandomLatency = false
    }

    func testConcurrentRequestsTriggerOnlyOneTokenRefresh() async throws {
        // Given: An expired session in storage
        let initialStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "expired_token_123",
                refreshToken: "ref_token_initial_456",
                expiresAt: Date().addingTimeInterval(-10), // Expired 10s ago
                user: User(id: "usr_1", name: "Ricardo Messon", email: "usuario@onest.com")
            )
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SimulatedURLProtocol.self]
        let session = URLSession(configuration: config)

        let coordinator = TokenRefreshCoordinator(tokenStorage: initialStorage, session: session)

        // When: 10 concurrent requests ask for a valid token simultaneously
        let concurrentCount = 10
        var tokens: [String] = []

        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<concurrentCount {
                group.addTask {
                    return try await coordinator.getValidAccessToken()
                }
            }

            for try await token in group {
                tokens.append(token)
            }
        }

        // Then:
        // 1. All 10 requests succeeded
        XCTAssertEqual(tokens.count, concurrentCount, "All concurrent requests should succeed")

        // 2. All 10 received the exact same fresh access token
        let firstToken = tokens.first
        XCTAssertNotNil(firstToken)
        XCTAssertTrue(tokens.allSatisfy { $0 == firstToken }, "All concurrent callers should receive the exact same new token")
        XCTAssertNotEqual(firstToken, "expired_token_123", "Returned token should be the newly refreshed token")

        // 3. Exactly ONE refresh network call was executed
        let executionCount = await coordinator.refreshExecutionCount
        XCTAssertEqual(executionCount, 1, "Only a single refresh request should have been dispatched across all concurrent callers")

        // 4. Token storage has the updated token
        XCTAssertEqual(initialStorage.getAccessToken(), firstToken)
    }

    func testExpiredRefreshTokenForcesLogoutAndThrowsSessionExpired() async throws {
        // Given: A session where the refresh token is also invalid/expired on the server
        let initialStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "expired_token",
                refreshToken: "invalid_expired_refresh_token",
                expiresAt: Date().addingTimeInterval(-30),
                user: User(id: "usr_1", name: "Ricardo", email: "ricardo@onest.com")
            )
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SimulatedURLProtocol.self]
        let session = URLSession(configuration: config)

        let coordinator = TokenRefreshCoordinator(tokenStorage: initialStorage, session: session)

        // When & Then: Refresh should fail with 401 and throw sessionExpired
        do {
            _ = try await coordinator.refreshToken()
            XCTFail("Should have thrown APIError.sessionExpired")
        } catch let error as APIError {
            XCTAssertEqual(error, APIError.sessionExpired)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Then: Storage should have been cleared
        XCTAssertNil(initialStorage.getSession(), "Session should be wiped from storage when refresh token expires")
    }

    func testValidTokenDoesNotTriggerRefresh() async throws {
        // Given: A token that is still fresh and valid
        let initialStorage = MockTokenStorage(
            initialSession: UserSession(
                accessToken: "still_valid_token",
                refreshToken: "valid_refresh_token",
                expiresAt: Date().addingTimeInterval(50), // 50 seconds remaining
                user: User(id: "usr_1", name: "Ricardo", email: "ricardo@onest.com")
            )
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SimulatedURLProtocol.self]
        let session = URLSession(configuration: config)

        let coordinator = TokenRefreshCoordinator(tokenStorage: initialStorage, session: session)

        // When: Requesting a valid access token
        let token = try await coordinator.getValidAccessToken()

        // Then: Returns existing token immediately without calling refresh
        XCTAssertEqual(token, "still_valid_token")
        let executionCount = await coordinator.refreshExecutionCount
        XCTAssertEqual(executionCount, 0, "No refresh should be triggered when token is still valid")
    }
}
