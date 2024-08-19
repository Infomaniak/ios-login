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
@testable import InfomaniakDI
import InfomaniakLogin
import UIKit

class ViewController: UIViewController, InfomaniakLoginDelegate, DeleteAccountDelegate {
    @LazyInjectService var loginService: InfomaniakLoginable
    @LazyInjectService var tokenService: InfomaniakTokenable

    func didCompleteDeleteAccount() {
        showAlert(title: "Account deleted", message: nil)
    }

    func didFailDeleteAccount(error: InfomaniakLoginError) {
        showAlert(title: "Delete Account Failed", message: error.localizedDescription)
    }

    func didFailLoginWith(error: Error) {
        showAlert(title: "Login Failed", message: error.localizedDescription)
    }

    func didCompleteLoginWith(code: String, verifier: String) {        
        tokenService.getApiTokenUsing(code: code, codeVerifier: verifier) { result in
            var title: String?
            var description: String?

            switch result {
            case .success(let token):
                title = "Login completed"
                description = "UserId: \(token.userId)\nToken: \(token.accessToken)"
            case .failure(let error):
                title = "Login error"
                description = error.localizedDescription
            }

            guard let title, let description else { return }

            Task { @MainActor in
                self.showAlert(title: title, message: description)
            }
        }
    }

    @IBAction func deleteAccount(_ sender: Any) {
        loginService.asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor(),
                                                  useEphemeralSession: true,
                                                  hideCreateAccountButton: true) { result in
            switch result {
            case .success((let code, let verifier)):
                self.tokenService.getApiTokenUsing(code: code, codeVerifier: verifier) { apiTokenResult in
                    switch apiTokenResult {
                    case .success(let token):
                        Task { @MainActor in
                            let deleteAccountViewController = DeleteAccountViewController.instantiateInViewController(
                                delegate: self,
                                accessToken: token.accessToken
                            )
                            self.present(deleteAccountViewController, animated: true)
                        }
                    case .failure:
                        break
                    }
                }
            case .failure:
                break
            }
        }
    }

    @IBAction func login(_ sender: UIButton) {
        loginService.loginFrom(viewController: self,
                               hideCreateAccountButton: true,
                               delegate: self)
    }

    @IBAction func webviewLogin(_ sender: UIButton) {
        loginService.setupWebviewNavbar(title: nil,
                                        titleColor: nil,
                                        color: nil,
                                        buttonColor: UIColor.white,
                                        clearCookie: true,
                                        timeOutMessage: "Problème de chargement !")
        loginService.webviewLoginFrom(viewController: self,
                                      hideCreateAccountButton: false,
                                      delegate: self)
    }

    @IBAction func asWebAuthentication(_ sender: Any) {
        loginService.asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor(),
                                                  useEphemeralSession: false,
                                                  hideCreateAccountButton: true,
                                                  delegate: self)
    }

    func showAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func refreshTokenConvert(_ sender: Any) {
        SimpleResolver.sharedResolver.removeAll()
        // Init with non infinite refresh token
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakLoginable.self) { _, _ in
            let clientId = "9473D73C-C20F-4971-9E10-D957C563FA68"
            let redirectUri = "com.infomaniak.drive://oauth2redirect"
            let login = InfomaniakLogin(config: .init(clientId: clientId, redirectURI: redirectUri, accessType: .offline))
            return login
        })
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakTokenable.self) { _, resolver in
            return try resolver.resolve(type: InfomaniakLoginable.self,
                                        forCustomTypeIdentifier: nil,
                                        factoryParameters: nil,
                                        resolver: resolver)
        })

        @InjectService var loginService: InfomaniakLoginable
        @InjectService var tokenService: InfomaniakTokenable

        loginService.asWebAuthenticationLoginFrom(anchor: .init(),
                                                  useEphemeralSession: false,
                                                  hideCreateAccountButton: true) { result in
            switch result {
            case .success(let success):
                self.tokenService.getApiTokenUsing(code: success.code, codeVerifier: success.verifier) { apiTokenResult in
                    var title: String?
                    var description: String?

                    switch apiTokenResult {
                    case .success(let token):
                        title = "Login completed"
                        description =
                            "UserId: \(token.userId)\nToken: \(token.accessToken)\nExpires in: \(token.expiresIn ?? -1)"
                        self.testSwapRefreshToken(apiToken: token)
                    case .failure(let error):
                        title = "Login error"
                        description = error.localizedDescription
                    }

                    print("refreshTokenConvert \(title ?? "")\n\(description ?? "")")
                }
            case .failure(let failure):
                Task { @MainActor in
                    self.showAlert(title: "Error", message: failure.localizedDescription)
                }
            }
        }
    }

    nonisolated func testSwapRefreshToken(apiToken: ApiToken) {
        SimpleResolver.sharedResolver.removeAll()
        // Init with infinite refresh token
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakLoginable.self) { _, _ in
            let clientId = "9473D73C-C20F-4971-9E10-D957C563FA68"
            let redirectUri = "com.infomaniak.drive://oauth2redirect"
            let login = InfomaniakLogin(config: .init(clientId: clientId, redirectURI: redirectUri, accessType: .none))
            return login
        })
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakTokenable.self) { _, resolver in
            return try resolver.resolve(type: InfomaniakLoginable.self,
                                        forCustomTypeIdentifier: nil,
                                        factoryParameters: nil,
                                        resolver: resolver)
        })

        @InjectService var loginService: InfomaniakLoginable
        @InjectService var tokenService: InfomaniakTokenable

        tokenService.refreshToken(token: apiToken) { result in
            var title: String?
            var description: String?

            switch result {
            case .success(let token):
                title = "Login completed"
                description = "UserId: \(token.userId)\nToken: \(token.accessToken)\nExpires in: \(token.expiresIn ?? -1)"
            case .failure(let error):
                title = "Login error"
                description = error.localizedDescription
            }

            guard let title, let description else { return }

            Task { @MainActor in
                self.showAlert(title: title, message: description)
            }
        }
    }
}
