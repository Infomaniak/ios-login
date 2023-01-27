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

import AuthenticationServices
import CommonCrypto
import InfomaniakCore
import InfomaniakDI
import SafariServices
import UIKit
import WebKit

/// Login delegation
public protocol InfomaniakLoginDelegate: AnyObject {
    func didCompleteLoginWith(code: String, verifier: String)
    func didFailLoginWith(error: Error)
}

/// Something that can authentify with Infomaniak
public protocol InfomaniakLoginable {
    func handleRedirectUri(url: URL) -> Bool

    func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor,
                                      useEphemeralSession: Bool,
                                      hideCreateAccountButton: Bool,
                                      completion: @escaping (Result<(code: String, verifier: String), Error>) -> Void)

    func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor,
                                      useEphemeralSession: Bool,
                                      hideCreateAccountButton: Bool,
                                      delegate: InfomaniakLoginDelegate?)

    func loginFrom(viewController: UIViewController,
                   hideCreateAccountButton: Bool,
                   delegate: InfomaniakLoginDelegate?)

    func webviewLoginFrom(viewController: UIViewController,
                          hideCreateAccountButton: Bool,
                          delegate: InfomaniakLoginDelegate?)

    func setupWebviewNavbar(title: String?,
                            titleColor: UIColor?,
                            color: UIColor?,
                            buttonColor: UIColor?,
                            clearCookie: Bool,
                            timeOutMessage: String?)

    func webviewHandleRedirectUri(url: URL) -> Bool
}

/// Something that can handle tokens
public protocol InfomaniakTokenable {
    /// Get an api token async (callback on background thread)
    func getApiTokenUsing(code: String, codeVerifier: String, completion: @escaping (ApiToken?, Error?) -> Void)

    /// Get an api token async from an application password (callback on background thread)
    func getApiToken(username: String, applicationPassword: String, completion: @escaping (ApiToken?, Error?) -> Void)

    /// Refresh api token async (callback on background thread)
    func refreshToken(token: ApiToken, completion: @escaping (ApiToken?, Error?) -> Void)

    /// Delete an api token async
    func deleteApiToken(token: ApiToken, onError: @escaping (Error) -> Void)
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

public class InfomaniakLogin: InfomaniakLoginable, InfomaniakTokenable {
    private static let LOGIN_API_URL = "https://login.infomaniak.com/"
    private static let GET_TOKEN_API_URL = LOGIN_API_URL + "token"
    
    let networkLogin: InfomaniakNetworkLoginable

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
    private var hideCreateAccountButton = true
    private var webViewController: WebViewController?
    private var webviewNavbarButtonColor: UIColor?
    private var webviewNavbarColor: UIColor?
    private var webviewNavbarTitle: String?
    private var webviewNavbarTitleColor: UIColor?
    private var webviewTimeOutMessage: String?

    public init(clientId: String,
                loginUrl: String = Constants.LOGIN_URL,
                redirectUri: String = "\(Bundle.main.bundleIdentifier ?? "")://oauth2redirect") {
        self.loginBaseUrl = loginUrl
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.networkLogin = InfomaniakNetworkLogin(clientId: clientId,
                                                   loginUrl: loginUrl,
                                                   redirectUri: redirectUri)
    }

    public func handleRedirectUri(url: URL) -> Bool {
        return InfomaniakLogin.checkResponse(url: url,
                                             onSuccess: { code in
                                                 safariViewController?.dismiss(animated: true) {
                                                     self.delegate?.didCompleteLoginWith(code: code, verifier: self.codeVerifier)
                                                 }
                                             },
                                             onFailure: { error in
                                                 safariViewController?.dismiss(animated: true) {
                                                     self.delegate?.didFailLoginWith(error: error)
                                                 }
                                             })
    }

    public func webviewHandleRedirectUri(url: URL) -> Bool {
        return InfomaniakLogin.checkResponse(url: url,
                                             onSuccess: { code in
                                                 webViewController?.dismiss(animated: true) {
                                                     self.delegate?.didCompleteLoginWith(code: code, verifier: self.codeVerifier)
                                                 }
                                             },
                                             onFailure: { error in
                                                 webViewController?.dismiss(animated: true) {
                                                     self.delegate?.didFailLoginWith(error: error)
                                                 }
                                             })
    }

    public func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor = ASPresentationAnchor(),
                                             useEphemeralSession: Bool = false,
                                             hideCreateAccountButton: Bool = true,
                                             completion: @escaping (Result<(code: String, verifier: String), Error>) -> Void) {
        self.hideCreateAccountButton = hideCreateAccountButton
        generatePkceCodes()

        guard let loginUrl = generateUrl(),
              let callbackUrl = URL(string: redirectUri),
              let callbackUrlScheme = callbackUrl.scheme else {
            return
        }

        let session = ASWebAuthenticationSession(url: loginUrl, callbackURLScheme: callbackUrlScheme) { callbackURL, error in
            if let callbackURL = callbackURL {
                _ = InfomaniakLogin.checkResponse(url: callbackURL,
                                                  onSuccess: { code in
                                                      completion(.success((code: code, verifier: self.codeVerifier)))
                                                  },
                                                  onFailure: { error in
                                                      completion(.failure(error))
                                                  })
            } else if let error = error {
                completion(.failure(error))
            }
        }
        asPresentationContext = PresentationContext(anchor: anchor)
        session.presentationContextProvider = asPresentationContext
        session.prefersEphemeralWebBrowserSession = useEphemeralSession
        session.start()
    }

    public func asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor = ASPresentationAnchor(),
                                             useEphemeralSession: Bool = false,
                                             hideCreateAccountButton: Bool = true,
                                             delegate: InfomaniakLoginDelegate? = nil) {
        self.delegate = delegate
        asWebAuthenticationLoginFrom(anchor: anchor, useEphemeralSession: useEphemeralSession,
                                     hideCreateAccountButton: hideCreateAccountButton) { result in
            switch result {
            case .success(let result):
                delegate?.didCompleteLoginWith(code: result.code, verifier: result.verifier)
            case .failure(let error):
                delegate?.didFailLoginWith(error: error)
            }
        }
    }

    public func loginFrom(viewController: UIViewController,
                          hideCreateAccountButton: Bool = true,
                          delegate: InfomaniakLoginDelegate? = nil) {
        self.hideCreateAccountButton = hideCreateAccountButton
        self.delegate = delegate
        generatePkceCodes()

        guard let loginUrl = generateUrl() else {
            return
        }

        safariViewController = SFSafariViewController(url: loginUrl)
        viewController.present(safariViewController!, animated: true)
    }

    public func webviewLoginFrom(viewController: UIViewController,
                                 hideCreateAccountButton: Bool = true,
                                 delegate: InfomaniakLoginDelegate? = nil) {
        self.hideCreateAccountButton = hideCreateAccountButton
        self.delegate = delegate
        generatePkceCodes()

        guard let loginUrl = generateUrl() else {
            return
        }

        let urlRequest = URLRequest(url: loginUrl)
        webViewController = WebViewController()

        if let navigationController = viewController as? UINavigationController {
            navigationController.pushViewController(webViewController!, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: webViewController!)
            viewController.present(navigationController, animated: true)
        }

        webViewController?.urlRequest = urlRequest
        webViewController?.redirectUri = redirectUri
        webViewController?.clearCookie = clearCookie
        webViewController?.navBarTitle = webviewNavbarTitle
        webViewController?.navBarTitleColor = webviewNavbarTitleColor
        webViewController?.navBarColor = webviewNavbarColor
        webViewController?.navBarButtonColor = webviewNavbarButtonColor
        webViewController?.timeOutMessage = webviewTimeOutMessage
    }

    public func setupWebviewNavbar(title: String?,
                                   titleColor: UIColor?,
                                   color: UIColor?,
                                   buttonColor: UIColor?,
                                   clearCookie: Bool = false,
                                   timeOutMessage: String?) {
        webviewNavbarTitle = title
        webviewNavbarTitleColor = titleColor
        webviewNavbarColor = color
        webviewNavbarButtonColor = buttonColor
        self.clearCookie = clearCookie
        webviewTimeOutMessage = timeOutMessage
    }

    // MARK: - InfomaniakTokenable

    public func getApiTokenUsing(code: String, codeVerifier: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        networkLogin.getApiTokenUsing(code: code, codeVerifier: codeVerifier, completion: completion)
    }

    public func getApiToken(username: String, applicationPassword: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        networkLogin.getApiToken(username: username, applicationPassword: applicationPassword, completion: completion)
    }

    public func refreshToken(token: ApiToken, completion: @escaping (ApiToken?, Error?) -> Void) {
        networkLogin.refreshToken(token: token, completion: completion)
    }

    public func deleteApiToken(token: ApiToken, onError: @escaping (Error) -> Void) {
        networkLogin.deleteApiToken(token: token, onError: onError)
    }

    // MARK: - Internal

    static func checkResponse(url: URL, onSuccess: (String) -> Void, onFailure: (InfomaniakLoginError) -> Void) -> Bool {
        if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
            onSuccess(code)
            return true
        } else {
            onFailure(.accessDenied)
            return false
        }
    }

    // MARK: - Private

    private func generatePkceCodes() {
        codeChallengeMethod = Constants.HASH_MODE_SHORT
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier)
    }

    /// Generate the complete login URL based on parameters and base
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
        if hideCreateAccountButton {
            urlComponents?.queryItems?.append(URLQueryItem(name: "hide_create_account", value: ""))
        }
        return urlComponents?.url
    }

    /// Generate a verifier code for PKCE challenge (rfc7636 4.1.)
    ///
    /// https://auth0.com/docs/api-auth/tutorials/authorization-code-grant-pkce
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Generate a challenge code for PKCE challenge (rfc7636 4.2.)
    ///
    /// https://auth0.com/docs/api-auth/tutorials/authorization-code-grant-pkce
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
