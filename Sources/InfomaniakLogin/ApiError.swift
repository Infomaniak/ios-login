//
//  File.swift
//  
//
//  Created by Philippe Weidmann on 13.08.20.
//

import Foundation

class ApiError: Codable {
    let error: String
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}
