/*
 Copyright 2020 Infomaniak Network SA

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

import AuthenticationServices
import CommonCrypto
import SafariServices
import UIKit
import WebKit

public protocol InfomaniakLoginDelegate: AnyObject {
    func didCompleteLoginWith(code: String, verifier: String)
    func didFailLoginWith(error: Error)
}

public enum Constants {
    public static let LOGIN_URL = "https://login.infomaniak.com/"
    public static let DELETEACCOUNT_URL = "https://manager.infomaniak.com/v3/ng/profile/user/dashboard?open-terminate-account-modal"
    public static let RESPONSE_TYPE = "code"
    public static let ACCESS_TYPE = "offline"
    public static let HASH_MODE = "SHA-256"
    public static let HASH_MODE_SHORT = "S256"

    public static func autologinUrl(to destination: String) -> URL? {
        return URL(string: "https://manager.infomaniak.com/v3/mobile_login/?url=\(destination)")
    }
}

class PresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}

public class InfomaniakLogin {
    private static let LOGIN_API_URL = "https://login.infomaniak.com/"
    private static let GET_TOKEN_API_URL = LOGIN_API_URL + "token"

    private static let instance = InfomaniakLogin()
    private var delegate: InfomaniakLoginDelegate?

    private var clientId: String!
    private var loginBaseUrl: String!
    private var redirectUri: String!

    private var codeChallenge: String!
    private var codeChallengeMethod: String!
    private var codeVerifier: String!

    private var asPresentationContext: PresentationContext?

    private var safariViewController: SFSafariViewController?

    private var clearCookie = false
    private var webViewController: WebViewController?
    private var webviewNavbarButtonColor: UIColor?
    private var webviewNavbarColor: UIColor?
    private var webviewNavbarTitle: String?
    private var webviewNavbarTitleColor: UIColor?
    private var webviewTimeOutMessage: String?

    private init() {
        // Singleton
    }

    public static func initWith(clientId: String,
                                loginUrl: String = Constants.LOGIN_URL,
                                redirectUri: String = "\(Bundle.main.bundleIdentifier ?? "")://oauth2redirect") {
        instance.loginBaseUrl = loginUrl
        instance.clientId = clientId
        instance.redirectUri = redirectUri
    }

    public static func handleRedirectUri(url: URL) -> Bool {
        return checkResponse(url: url,
                             onSuccess: { code in
                                 instance.safariViewController?.dismiss(animated: true) {
                                     instance.delegate?.didCompleteLoginWith(code: code, verifier: instance.codeVerifier)
                                 }
                             },

                             onFailure: { error in
                                 instance.safariViewController?.dismiss(animated: true) {
                                     instance.delegate?.didFailLoginWith(error: error)
                                 }
                             })
    }

    static func webviewHandleRedirectUri(url: URL) -> Bool {
        return checkResponse(url: url,
                             onSuccess: { code in
                                 instance.webViewController?.dismiss(animated: true) {
                                     instance.delegate?.didCompleteLoginWith(code: code, verifier: instance.codeVerifier)
                                 }
                             },

                             onFailure: { error in
                                 instance.webViewController?.dismiss(animated: true) {
                                     instance.delegate?.didFailLoginWith(error: error)
                                 }
                             })
    }

    static func checkResponse(url: URL, onSuccess: (String) -> Void, onFailure: (InfomaniakLoginError) -> Void) -> Bool {
        if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
            onSuccess(code)
            return true
        } else {
            onFailure(.accessDenied)
            return false
        }
    }

    @available(iOS 13.0, *)
    public static func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor = ASPresentationAnchor(), useEphemeralSession: Bool = false, completion: @escaping (Result<(code: String, verifier: String), Error>) -> Void) {
        let instance = InfomaniakLogin.instance
        instance.generatePkceCodes()

        guard let loginUrl = instance.generateUrl(),
              let callbackUrl = URL(string: instance.redirectUri),
              let callbackUrlScheme = callbackUrl.scheme else {
            return
        }

        let session = ASWebAuthenticationSession(url: loginUrl, callbackURLScheme: callbackUrlScheme) { callbackURL, error in
            if let callbackURL = callbackURL {
                _ = checkResponse(url: callbackURL,
                                  onSuccess: { code in
                                      completion(.success((code: code, verifier: instance.codeVerifier)))
                                  },
                                  onFailure: { error in
                                      completion(.failure(error))
                                  })
            } else if let error = error {
                completion(.failure(error))
            }
        }
        instance.asPresentationContext = PresentationContext(anchor: anchor)
        session.presentationContextProvider = instance.asPresentationContext
        session.prefersEphemeralWebBrowserSession = useEphemeralSession
        session.start()
    }

    @available(iOS 13.0, *)
    public static func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor = ASPresentationAnchor(), useEphemeralSession: Bool = false, delegate: InfomaniakLoginDelegate? = nil) {
        let instance = InfomaniakLogin.instance
        instance.delegate = delegate
        asWebAuthenticationLoginFrom(anchor: anchor, useEphemeralSession: useEphemeralSession) { result in
            switch result {
            case .success(let result):
                instance.delegate?.didCompleteLoginWith(code: result.code, verifier: result.verifier)
            case .failure(let error):
                instance.delegate?.didFailLoginWith(error: error)
            }
        }
    }

    public static func loginFrom(viewController: UIViewController, delegate: InfomaniakLoginDelegate? = nil) {
        let instance = InfomaniakLogin.instance
        instance.delegate = delegate
        instance.generatePkceCodes()

        guard let loginUrl = instance.generateUrl() else {
            return
        }

        instance.safariViewController = SFSafariViewController(url: loginUrl)
        viewController.present(instance.safariViewController!, animated: true)
    }

    public static func webviewLoginFrom(viewController: UIViewController, delegate: InfomaniakLoginDelegate? = nil) {
        let instance = InfomaniakLogin.instance
        instance.delegate = delegate
        instance.generatePkceCodes()

        guard let loginUrl = instance.generateUrl() else {
            return
        }

        let urlRequest = URLRequest(url: loginUrl)
        instance.webViewController = WebViewController()

        if let navigationController = viewController as? UINavigationController {
            navigationController.pushViewController(instance.webViewController!, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: instance.webViewController!)
            viewController.present(navigationController, animated: true)
        }

        instance.webViewController?.urlRequest = urlRequest
        instance.webViewController?.redirectUri = instance.redirectUri
        instance.webViewController?.clearCookie = instance.clearCookie
        instance.webViewController?.navBarTitle = instance.webviewNavbarTitle
        instance.webViewController?.navBarTitleColor = instance.webviewNavbarTitleColor
        instance.webViewController?.navBarColor = instance.webviewNavbarColor
        instance.webViewController?.navBarButtonColor = instance.webviewNavbarButtonColor
        instance.webViewController?.timeOutMessage = instance.webviewTimeOutMessage
    }

    public static func setupWebviewNavbar(title: String?, titleColor: UIColor?, color: UIColor?, buttonColor: UIColor?, clearCookie: Bool = false, timeOutMessage: String?) {
        instance.webviewNavbarTitle = title
        instance.webviewNavbarTitleColor = titleColor
        instance.webviewNavbarColor = color
        instance.webviewNavbarButtonColor = buttonColor
        instance.clearCookie = clearCookie
        instance.webviewTimeOutMessage = timeOutMessage
    }

    /**
     * Get an api token async (callback on background thread)
     */
    public static func getApiTokenUsing(code: String, codeVerifier: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "authorization_code",
            "client_id": instance.clientId!,
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": instance.redirectUri ?? ""
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    /**
     * Get an api token async from an application password (callback on background thread)
     */
    public static func getApiToken(username: String, applicationPassword: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "password",
            "access_type": "offline",
            "client_id": instance.clientId!,
            "username": username,
            "password": applicationPassword
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    /**
     * Refresh api token async (callback on background thread)
     */
    public static func refreshToken(token: ApiToken, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": instance.clientId!,
            "refresh_token": token.refreshToken
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    private static func getApiToken(request: URLRequest, completion: @escaping (ApiToken?, Error?) -> Void) {
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
                    let apiError = try JSONDecoder().decode(ApiError.self, from: data)
                    completion(nil, NSError(domain: apiError.error, code: response.statusCode, userInfo: ["Error": apiError]))
                }
            } catch {
                completion(nil, error)
            }
        }.resume()
    }

    private func generatePkceCodes() {
        codeChallengeMethod = Constants.HASH_MODE_SHORT
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier)
    }

    /**
     * Generate the complete login URL based on parameters and base
     */
    private func generateUrl() -> URL? {
        var urlComponents = URLComponents(string: loginBaseUrl)
        urlComponents?.path = "/authorize"
        urlComponents?.queryItems = [
            URLQueryItem(name: "response_type", value: Constants.RESPONSE_TYPE),
            URLQueryItem(name: "access_type", value: Constants.ACCESS_TYPE),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
            URLQueryItem(name: "code_challenge", value: codeChallenge)
        ]
        return urlComponents?.url
    }

    /**
     * Generate a verifier code for PKCE challenge (rfc7636 4.1.)
     * https://auth0.com/docs/api-auth/tutorials/authorization-code-grant-pkce
     */
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /**
     * Generate a challenge code for PKCE challenge (rfc7636 4.2.)
     * https://auth0.com/docs/api-auth/tutorials/authorization-code-grant-pkce
     */
    private func generateCodeChallenge(codeVerifier: String) -> String {
        guard let data = codeVerifier.data(using: .utf8) else {
            return ""
        }
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }

        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
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
