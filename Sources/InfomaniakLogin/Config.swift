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

public enum AccessType: String {
    case offline
}

public enum ResponseType: String {
    case code
}

public extension InfomaniakLogin {
    struct Config {
        let clientId: String
        let loginURL: URL
        let redirectURI: String
        let responseType: ResponseType
        let accessType: AccessType
        let hashMode: String
        let hashModeShort: String

        public init(
            clientId: String,
            loginURL: URL = URL(string: "https://login.infomaniak.com/")!,
            redirectURI: String = "\(Bundle.main.bundleIdentifier ?? "")://oauth2redirect",
            responseType: ResponseType = .code,
            accessType: AccessType = .offline,
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
