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

@frozen public struct ApiToken: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let scope: String
    public let tokenType: String
    public let userId: Int
    public let expiresIn: Int?
    public let expirationDate: Date?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
        case scope
        case expirationDate
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        let maybeExpiresIn = try values.decodeIfPresent(Int.self, forKey: .expiresIn)
        expiresIn = maybeExpiresIn
        refreshToken = try values.decodeIfPresent(String.self, forKey: .refreshToken)
        scope = try values.decode(String.self, forKey: .scope)
        tokenType = try values.decode(String.self, forKey: .tokenType)
        userId = try values.decode(Int.self, forKey: .userId)

        if let maybeExpiresIn {
            let newExpirationDate = Date().addingTimeInterval(TimeInterval(Double(maybeExpiresIn)))
            expirationDate = try values.decodeIfPresent(Date.self, forKey: .expirationDate) ?? newExpirationDate
        } else {
            expirationDate = nil
        }
    }

    public init(
        accessToken: String,
        expiresIn: Int,
        refreshToken: String,
        scope: String,
        tokenType: String,
        userId: Int,
        expirationDate: Date
    ) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
        self.userId = userId
        self.expirationDate = expirationDate
    }
}

// MARK: - Token Logging

public extension ApiToken {
    var truncatedAccessToken: String {
        truncateToken(accessToken)
    }

    var truncatedRefreshToken: String {
        guard let refreshToken else { return "" }
        return truncateToken(refreshToken)
    }

    internal func truncateToken(_ token: String) -> String {
        String(token.prefix(4) + "-*****-" + token.suffix(4))
    }
}
