//
//  SimulatedURLProtocol.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public final class SimulatedURLProtocol: URLProtocol {
    private static let simulatedHost = "api.onest.com"

    public override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.host == simulatedHost
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    public override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: APIError.invalidURL)
            return
        }

        let backend = SimulatedBackend.shared
        let path = url.path
        let method = request.httpMethod?.uppercased() ?? "GET"
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        let idempotencyKey = request.value(forHTTPHeaderField: "Idempotency-Key")

        // Execute on background thread to respect latency without freezing main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Simulated random latency of 0.5s - 2.0s for GET /loans
            if path == "/loans" && method == "GET" && backend.enableRandomLatency {
                let latency = Double.random(in: 0.5...2.0)
                Thread.sleep(forTimeInterval: latency)
            } else if backend.enableRandomLatency {
                // Minor realistic latency of 100-300ms for other requests
                let minorLatency = Double.random(in: 0.1...0.3)
                Thread.sleep(forTimeInterval: minorLatency)
            }

            let result: (statusCode: Int, body: Data)

            switch (method, path) {
            case ("POST", "/auth/login"):
                if let bodyData = self.extractBodyData(),
                   let loginReq = try? JSONDecoder().decode(LoginRequest.self, from: bodyData) {
                    result = backend.handleLogin(request: loginReq)
                } else {
                    let err = """
                    {"error": "BAD_REQUEST", "message": "Cuerpo de solicitud inválido."}
                    """
                    result = (400, err.data(using: .utf8)!)
                }

            case ("POST", "/auth/refresh"):
                if let bodyData = self.extractBodyData(),
                   let refreshReq = try? JSONDecoder().decode(TokenRefreshRequest.self, from: bodyData) {
                    result = backend.handleRefresh(request: refreshReq)
                } else {
                    let err = """
                    {"error": "BAD_REQUEST", "message": "Cuerpo de solicitud inválido."}
                    """
                    result = (400, err.data(using: .utf8)!)
                }

            case ("GET", "/loans"):
                result = backend.handleGetLoans(authHeader: authHeader)

            case ("GET", let p) where p.hasPrefix("/loans/"):
                let loanId = String(p.dropFirst("/loans/".count))
                result = backend.handleGetLoanDetail(id: loanId, authHeader: authHeader)

            case ("POST", "/loans/quote"):
                if let bodyData = self.extractBodyData(),
                   let quoteReq = try? JSONDecoder().decode(LoanQuoteRequest.self, from: bodyData) {
                    result = backend.handleQuote(request: quoteReq, authHeader: authHeader)
                } else {
                    let err = """
                    {"error": "BAD_REQUEST", "message": "Cuerpo de cotización inválido."}
                    """
                    result = (400, err.data(using: .utf8)!)
                }

            case ("POST", "/loans"):
                if let bodyData = self.extractBodyData(),
                   let createReq = try? JSONDecoder().decode(CreateLoanRequest.self, from: bodyData) {
                    result = backend.handleCreateLoan(
                        request: createReq,
                        idempotencyKey: idempotencyKey,
                        authHeader: authHeader
                    )
                } else {
                    let err = """
                    {"error": "BAD_REQUEST", "message": "Cuerpo de solicitud de préstamo inválido."}
                    """
                    result = (400, err.data(using: .utf8)!)
                }

            default:
                let notFoundJson = """
                {"error": "NOT_FOUND", "message": "Ruta no encontrada en el servidor simulado."}
                """
                result = (404, notFoundJson.data(using: .utf8)!)
            }

            guard let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: result.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": "application/json",
                    "Server": "Onest-Simulated-Gateway"
                ]
            ) else {
                self.client?.urlProtocol(self, didFailWithError: APIError.networkError("No se pudo crear HTTPURLResponse"))
                return
            }

            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: result.body)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    public override func stopLoading() {
        // No-op for simulated requests
    }

    private func extractBodyData() -> Data? {
        if let body = request.httpBody {
            return body
        }
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            var data = Data()
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else if read < 0 {
                    return nil
                } else {
                    break
                }
            }
            return data
        }
        return nil
    }
}
