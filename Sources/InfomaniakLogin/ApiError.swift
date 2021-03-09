//
//  ApiError.swift
//  InfomaniakLogin
//
//  Created by Philippe Weidmann on 13.08.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation

@objc public class ApiError: NSObject, Codable {
    @objc public let error: String
    @objc public let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}
