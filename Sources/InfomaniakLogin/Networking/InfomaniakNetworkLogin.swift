/*
 Copyright 2023 Infomaniak Network SA

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// Something that can keep the network stack authenticated
public protocol InfomaniakNetworkLoginable {
    /// Get an api token async (callback on background thread)
    func getApiTokenUsing(code: String, codeVerifier: String, completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void)

    /// Get an api token
    func apiTokenUsing(code: String, codeVerifier: String) async throws -> ApiToken

    /// Refresh api token async (callback on background thread)
    func refreshToken(token: ApiToken, completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void)

    /// Refresh api token
    func refreshToken(token: ApiToken) async throws -> ApiToken

    /// Delete an api token async
    func deleteApiToken(token: ApiToken, completion: @Sendable @escaping (Result<Void, Error>) -> Void)

    /// Delete an api token
    func deleteApiToken(token: ApiToken) async throws

    func derivateApiToken(
        using token: ApiToken,
        attestationToken: String,
        completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void
    )

    func derivateApiToken(using token: ApiToken, attestationToken: String,) async throws -> ApiToken
}

public class InfomaniakNetworkLogin: InfomaniakNetworkLoginable {
    private let config: InfomaniakLogin.Config
    private let tokenApiURL: URL

    // MARK: Public

    public init(config: InfomaniakLogin.Config) {
        self.config = config
        tokenApiURL = config.loginURL.appendingPathComponent("token")
    }

    public func apiTokenUsing(code: String, codeVerifier: String) async throws -> ApiToken {
        return try await withCheckedThrowingContinuation { continuation in
            getApiTokenUsing(code: code, codeVerifier: codeVerifier) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func getApiTokenUsing(code: String,
                                 codeVerifier: String,
                                 completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void) {
        var request = URLRequest(url: tokenApiURL)

        let parameterDictionary: [String: Any] = [
            "grant_type": "authorization_code",
            "client_id": config.clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": config.redirectURI
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    public func refreshToken(token: ApiToken) async throws -> ApiToken {
        return try await withCheckedThrowingContinuation { continuation in
            refreshToken(token: token) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func refreshToken(token: ApiToken, completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void) {
        guard let refreshToken = token.refreshToken else {
            completion(.failure(InfomaniakLoginError.noRefreshToken))
            return
        }

        var request = URLRequest(url: tokenApiURL)

        var parameterDictionary: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": config.clientId,
            "refresh_token": refreshToken
        ]

        if config.accessType == .none {
            parameterDictionary["duration"] = "infinite"
        }

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    public func derivateApiToken(using token: ApiToken, attestationToken: String) async throws -> ApiToken {
        return try await withCheckedThrowingContinuation { continuation in
            derivateApiToken(using: token, attestationToken: attestationToken) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func derivateApiToken(using apiToken: ApiToken,
                                 attestationToken: String,
                                 completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void) {
        var request = URLRequest(url: tokenApiURL)

        var parameterDictionary: [String: Any] = [
            "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
            "subject_token": apiToken.accessToken,
            "subject_token_type": "urn:ietf:params:oauth:token-type:access_token",
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": attestationToken,
            "client_id": config.clientId,
        ]
        if config.accessType == .none {
            parameterDictionary["duration"] = "infinite"
        }

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    public func deleteApiToken(token: ApiToken) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            deleteApiToken(token: token) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func deleteApiToken(token: ApiToken, completion: @Sendable @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: tokenApiURL)
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse, let data else {
                completion(.failure(sessionError ?? InfomaniakLoginError.unknownNetworkError))
                return
            }

            do {
                if !response.isSuccessful() {
                    let apiDeleteToken = try JSONDecoder().decode(ApiDeleteToken.self, from: data)
                    completion(.failure(NSError(
                        domain: apiDeleteToken.error!,
                        code: response.statusCode,
                        userInfo: ["Error": apiDeleteToken.error!]
                    )))
                } else {
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: Private

    /// Make the get token network call
    private func getApiToken(request: URLRequest, completion: @Sendable @escaping (Result<ApiToken, Error>) -> Void) {
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse,
                  let data = data, data.count > 0 else {
                completion(.failure(sessionError ?? InfomaniakLoginError.unknownNetworkError))
                return
            }

            do {
                if response.isSuccessful() {
                    let apiToken = try JSONDecoder().decode(ApiToken.self, from: data)
                    completion(.success(apiToken))
                } else {
                    let apiError = try JSONDecoder().decode(LoginApiError.self, from: data)
                    completion(.failure(NSError(
                        domain: apiError.error,
                        code: response.statusCode,
                        userInfo: ["Error": apiError]
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension HTTPURLResponse {
    func isSuccessful() -> Bool {
        return statusCode >= 200 && statusCode <= 299
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
