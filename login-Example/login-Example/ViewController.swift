//
//  ViewController.swift
//  login-Example
//
//  Created by Ambroise Decouttere on 27/05/2020.
//  Copyright © 2020 infomaniak. All rights reserved.
//

import UIKit
import InfomaniakLogin

let clientId = "1d06ddb8-65d7-4e45-a1b1-276f5da71833"
let redirectUri = "com.infomaniak.auth://oauth2redirect"

class ViewController: UIViewController, InfomaniakLoginDelegate {

    func didCompleteLoginWith(code: String?, verifier: String) {
        if let validCode = code {
            InfomaniakLogin.getApiTokenUsing(code: validCode, codeVerifier: verifier) { (token, error) in }
        } else {
            print("DENY")
        }
    }

    @IBAction func login(_ sender: UIButton) {
        InfomaniakLogin.loginFrom(viewController: self, delegate: self, clientId: clientId, redirectUri: redirectUri)
    }
    
}

