//
//  ApiToken.swift
//  Infomaniak
//
//  Created by Philippe Weidmann on 16.04.20.
//

import Foundation

@objc public class ApiToken: NSObject, Codable {

    public var accessToken: String
    public var expiresIn: Int
    public var refreshToken: String
    public var scope: String
    public var tokenType: String
    public var userId: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
        case scope
    }

}
