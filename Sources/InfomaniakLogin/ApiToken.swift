//
//  ApiToken.swift
//  Infomaniak
//
//  Created by Philippe Weidmann on 16.04.20.
//

import Foundation

@objc public class ApiToken: NSObject, Codable {

    @objc public var accessToken: String
    @objc public var expiresIn: Int
    @objc public var refreshToken: String
    @objc public var scope: String
    @objc public var tokenType: String
    @objc public var userId: Int
    @objc public var expirationDate: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
        case scope
        case expirationDate
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        expiresIn = try values.decode(Int.self, forKey: .expiresIn)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        scope = try values.decode(String.self, forKey: .scope)
        tokenType = try values.decode(String.self, forKey: .tokenType)
        userId = try values.decode(Int.self, forKey: .userId)

        let newExpirationDate = Date().addingTimeInterval(TimeInterval(Double(expiresIn)))
        expirationDate = try values.decodeIfPresent(Date.self, forKey: .expirationDate) ?? newExpirationDate
    }

}
