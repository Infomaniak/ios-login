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
    func getApiTokenUsing(code: String, codeVerifier: String, completion: @Sendable @escaping (ApiToken?, Error?) -> Void)

    /// Refresh api token async (callback on background thread)
    func refreshToken(token: ApiToken, completion: @Sendable @escaping (ApiToken?, Error?) -> Void)

    /// Delete an api token async
    func deleteApiToken(token: ApiToken, onError: @Sendable @escaping (Error) -> Void)
}

public class InfomaniakNetworkLogin: InfomaniakNetworkLoginable {
    private let config: InfomaniakLogin.Config
    private let tokenApiURL: URL

    // MARK: Public

    public init(config: InfomaniakLogin.Config) {
        self.config = config
        tokenApiURL = config.loginURL.appendingPathComponent("token")
    }

    public func getApiTokenUsing(code: String, codeVerifier: String, completion: @Sendable @escaping (ApiToken?, Error?) -> Void) {
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

    public func refreshToken(token: ApiToken, completion: @Sendable @escaping (ApiToken?, Error?) -> Void) {
        guard let refreshToken = token.refreshToken else {
            completion(nil, InfomaniakLoginError.noRefreshToken)
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

    public func deleteApiToken(token: ApiToken, onError: @Sendable @escaping (Error) -> Void) {
        var request = URLRequest(url: tokenApiURL)
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse, let data else {
                if let sessionError {
                    onError(sessionError)
                }
                return
            }

            do {
                if !response.isSuccessful() {
                    let apiDeleteToken = try JSONDecoder().decode(ApiDeleteToken.self, from: data)
                    onError(NSError(
                        domain: apiDeleteToken.error!,
                        code: response.statusCode,
                        userInfo: ["Error": apiDeleteToken.error!]
                    ))
                }
            } catch {
                onError(error)
            }
        }.resume()
    }

    // MARK: Private

    /// Make the get token network call
    private func getApiToken(request: URLRequest, completion: @Sendable @escaping (ApiToken?, Error?) -> Void) {
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse,
                  let data = data, data.count > 0 else {
                completion(nil, sessionError)
                return
            }

            do {
                if response.isSuccessful() {
                    let apiToken = try JSONDecoder().decode(ApiToken.self, from: data)
                    completion(apiToken, nil)
                } else {
                    let apiError = try JSONDecoder().decode(LoginApiError.self, from: data)
                    completion(nil, NSError(domain: apiError.error, code: response.statusCode, userInfo: ["Error": apiError]))
                }
            } catch {
                completion(nil, error)
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
