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
import InfomaniakDI
import InfomaniakLogin
import UIKit

class ViewController: UIViewController, InfomaniakLoginDelegate, DeleteAccountDelegate {
    @InjectService var loginService: InfomaniakLoginable
    @InjectService var tokenService: InfomaniakTokenable

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
        tokenService.getApiTokenUsing(code: code, codeVerifier: verifier) { token, error in
            var title: String?
            var description: String?

            if let token = token {
                title = "Login completed"
                description = "UserId: \(token.userId)\nToken: \(token.accessToken)"
            } else if let error = error {
                title = "Login error"
                description = error.localizedDescription
            }
            if let title = title,
               let description = description {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlert(title: title, message: description)
                }
            }
        }
    }

    @IBAction func deleteAccount(_ sender: Any) {
        if #available(iOS 13.0, *) {
            loginService.asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor(),
                                                      useEphemeralSession: true,
                                                      hideCreateAccountButton: true) { result in
                switch result {
                case .success((let code, let verifier)):
                    self.tokenService.getApiTokenUsing(code: code, codeVerifier: verifier) { token, _ in
                        if let token = token {
                            DispatchQueue.main.async {
                                let deleteAccountViewController = DeleteAccountViewController.instantiateInViewController(delegate: self,
                                                                                                                          accessToken: token.accessToken)
                                self.present(deleteAccountViewController, animated: true)
                            }
                        }
                    }
                case .failure:
                    break
                }
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
        if #available(iOS 13.0, *) {
            loginService.asWebAuthenticationLoginFrom(anchor: ASPresentationAnchor(),
                                                      useEphemeralSession: true,
                                                      hideCreateAccountButton: true,
                                                      delegate: self)
        }
    }

    func showAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alertController, animated: true, completion: nil)
    }
}
