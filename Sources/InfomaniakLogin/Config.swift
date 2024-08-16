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

@frozen public enum AccessType: String {
    /// When using `offline` accessToken has an expiration date and a refresh token is returned by the back-end
    case offline
}

@frozen public enum ResponseType: String {
    case code
}

public extension InfomaniakLogin {
    @frozen struct Config {
        public let clientId: String
        public let loginURL: URL
        public let redirectURI: String
        public let responseType: ResponseType
        public let accessType: AccessType?
        public let hashMode: String
        public let hashModeShort: String

        /// Initializes an OAuth2 configuration for a given Infomaniak client app
        ///
        /// - Parameters:
        ///   - clientId: An identifier provided by the backend.
        ///   - loginURL: Base URL for login calls, defaults to production. Can be replaced with preprod.
        ///   - redirectURI: Should match the app bundle ID.
        ///   - responseType: The response type, currently only supports `.code`.
        ///   - accessType: Use `.offline` for refresh token-based auth, `.none` or `nil` for non expiring token.
        ///   - hashMode: The hash mode, defaults to "SHA-256".
        ///   - hashModeShort: A short version of the hash mode, defaults to "S256".
        public init(
            clientId: String,
            loginURL: URL = URL(string: "https://login.infomaniak.com/")!,
            redirectURI: String = "\(Bundle.main.bundleIdentifier ?? "")://oauth2redirect",
            responseType: ResponseType = .code,
            accessType: AccessType? = .offline,
            hashMode: String = "SHA-256",
            hashModeShort: String = "S256"
        ) {
            self.clientId = clientId
            self.loginURL = loginURL
            self.redirectURI = redirectURI
            self.responseType = responseType
            self.accessType = accessType
            self.hashMode = hashMode
            self.hashModeShort = hashModeShort
        }
    }
}
