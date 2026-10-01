//
//  APIError.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public enum APIError: LocalizedError, Equatable {
    case invalidURL
    case unauthorized(message: String)
    case notFound(message: String)
    case unprocessableEntity(message: String)
    case serverError(message: String)
    case missingIdempotencyKey
    case networkError(String)
    case decodingError(String)
    case sessionExpired
    case unknown(Int, String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL proporcionada no es válida."
        case .unauthorized(let message):
            return message.isEmpty ? "Credenciales inválidas o sesión no autorizada." : message
        case .notFound(let message):
            return message.isEmpty ? "El recurso solicitado no fue encontrado." : message
        case .unprocessableEntity(let message):
            return message.isEmpty ? "Los datos enviados no cumplen con los requisitos." : message
        case .serverError(let message):
            return message.isEmpty ? "Ocurrió un error en el servidor. Por favor intenta de nuevo." : message
        case .missingIdempotencyKey:
            return "Se requiere el encabezado Idempotency-Key para procesar la solicitud."
        case .networkError(let message):
            return "Error de conexión: \(message)"
        case .decodingError(let message):
            return "Error al procesar la respuesta del servidor: \(message)"
        case .sessionExpired:
            return "Tu sesión ha expirado. Por favor inicia sesión nuevamente."
        case .unknown(let code, let message):
            return "Error inesperado (\(code)): \(message)"
        }
    }

    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.missingIdempotencyKey, .missingIdempotencyKey),
             (.sessionExpired, .sessionExpired):
            return true
        case (.unauthorized(let l), .unauthorized(let r)),
             (.notFound(let l), .notFound(let r)),
             (.unprocessableEntity(let l), .unprocessableEntity(let r)),
             (.serverError(let l), .serverError(let r)),
             (.networkError(let l), .networkError(let r)),
             (.decodingError(let l), .decodingError(let r)):
            return l == r
        case (.unknown(let c1, let m1), .unknown(let c2, let m2)):
            return c1 == c2 && m1 == m2
        default:
            return false
        }
    }
}
