//
//  AppDelegate.swift
//  login-Example
//
//  Created by Ambroise Decouttere on 27/05/2020.
//  Copyright © 2020 infomaniak. All rights reserved.
//

import UIKit
import InfomaniakLogin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let clientId = "1d06ddb8-65d7-4e45-a1b1-276f5da71833"
        let redirectUri = "com.infomaniak.auth://oauth2redirect"
        
        InfomaniakLogin.initWith(clientId: clientId, redirectUri: redirectUri)
        return true
    }
    // Needed if there is no SceneDelegate.swift file

    var window: UIWindow?

     func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
         return InfomaniakLogin.handleRedirectUri(url: url)
     }


}

