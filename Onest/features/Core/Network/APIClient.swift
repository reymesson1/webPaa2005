//
//  APIClient.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

public final class APIClient: APIClientProtocol, @unchecked Sendable {
    public static let shared = APIClient()

    private let session: URLSession
    private let tokenStorage: TokenStorageProtocol
    public let refreshCoordinator: TokenRefreshCoordinator

    public init(
        tokenStorage: TokenStorageProtocol = KeychainManager.shared,
        session: URLSession? = nil
    ) {
        self.tokenStorage = tokenStorage

        if let providedSession = session {
            self.session = providedSession
        } else {
            let config = URLSessionConfiguration.default
            config.protocolClasses = [SimulatedURLProtocol.self]
            config.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: config)
        }

        self.refreshCoordinator = TokenRefreshCoordinator(
            tokenStorage: tokenStorage,
            session: self.session
        )
    }

    public func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        var token: String? = nil

        if endpoint.requiresAuth {
            do {
                token = try await refreshCoordinator.getValidAccessToken()
            } catch {
                throw error
            }
        }

        var urlRequest = try endpoint.buildRequest(accessToken: token)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Respuesta de red inválida.")
        }

        // Automatic retry on 401 for authenticated endpoints
        if httpResponse.statusCode == 401 && endpoint.requiresAuth {
            do {
                let newToken = try await refreshCoordinator.refreshToken()
                urlRequest = try endpoint.buildRequest(accessToken: newToken)
                let (retryData, retryResponse) = try await session.data(for: urlRequest)

                guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.networkError("Respuesta de red inválida tras reintento.")
                }

                return try handleResponse(data: retryData, httpResponse: retryHttpResponse)
            } catch {
                throw error
            }
        }

        return try handleResponse(data: data, httpResponse: httpResponse)
    }

    private func handleResponse<T: Decodable>(data: Data, httpResponse: HTTPURLResponse) throws -> T {
        let statusCode = httpResponse.statusCode

        guard (200...299).contains(statusCode) else {
            let errorMessage = parseErrorMessage(from: data)

            switch statusCode {
            case 400:
                throw APIError.unprocessableEntity(message: errorMessage.isEmpty ? "Solicitud incorrecta." : errorMessage)
            case 401:
                throw APIError.unauthorized(message: errorMessage)
            case 404:
                throw APIError.notFound(message: errorMessage)
            case 422:
                throw APIError.unprocessableEntity(message: errorMessage)
            case 500:
                throw APIError.serverError(message: errorMessage)
            default:
                throw APIError.unknown(statusCode, errorMessage)
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    private func parseErrorMessage(from data: Data) -> String {
        struct ServerErrorPayload: Decodable {
            let error: String?
            let message: String?
        }

        if let payload = try? JSONDecoder().decode(ServerErrorPayload.self, from: data),
           let message = payload.message {
            return message
        }

        if let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }

        return ""
    }
}
