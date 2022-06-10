/*
 Copyright 2022 Infomaniak Network SA

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

public enum InfomaniakLoginError: LocalizedError {
    public typealias HTTPStatusCode = Int
    public typealias AccessToken = String

    case accessDenied
    case navigationFailed(Error)
    case navigationCancelled(HTTPStatusCode?, URL?)
    case invalidAccessToken(AccessToken?)
    case invalidUrl

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access denied"
        case .navigationFailed:
            return "Navigation failed"
        case .navigationCancelled:
            return "Navigation cancelled"
        case .invalidAccessToken:
            return "Invalid access token"
        case .invalidUrl:
            return "Invalid url"
        }
    }
}
