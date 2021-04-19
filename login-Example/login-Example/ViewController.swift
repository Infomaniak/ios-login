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

import UIKit
import InfomaniakLogin

class ViewController: UIViewController, InfomaniakLoginDelegate {
    func didFailLoginWith(error: String) {
        showError(error: error)
    }

    func didCompleteLoginWith(code: String, verifier: String) {
        InfomaniakLogin.getApiTokenUsing(code: code, codeVerifier: verifier) { (token, error) in }
    }

    @IBAction func login(_ sender: UIButton) {
        InfomaniakLogin.loginFrom(viewController: self, delegate: self)
    }

    @IBAction func webviewLogin(_ sender: UIButton) {
        InfomaniakLogin.setupWebviewNavbar(title: nil, titleColor: nil, color: nil, buttonColor: UIColor.white, clearCookie: true, timeOutMessage: "Problème de chargement !")
        InfomaniakLogin.webviewLoginFrom(viewController: self, delegate: self)
    }


    func showError(error: String) {
        let alertController = UIAlertController(title: error, message:
                nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Fermer", style: .default, handler: {
            _ in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }

}
