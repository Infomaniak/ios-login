//
//  File.swift
//
//
//  Created by adrien on 11.01.23.
//

import InfomaniakCore
import UIKit

public extension OrganisationAccount {
    var backgroundColor: UIColor {
        let nameAscii: [Int32] = name.replacingOccurrences(of: "/[^a-zA-Z ]+/", with: "", options: [.regularExpression]).compactMap { $0.asciiValue }.compactMap { Int32($0) }
        let hashCode: Int32 = nameAscii.reduce(0) { a, b in
            ((a &<< Int32(5)) &- a) &+ Int32(b)
        }
        let colorIndex = (abs(Int(hashCode)) &+ id) % 8
        return UIColor(named: "organisationColor\(colorIndex)")!
    }
}
