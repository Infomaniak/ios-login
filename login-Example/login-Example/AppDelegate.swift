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

    //Needed if SceneDelegate is deleted
    //var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("Redirect Uri")
        return InfomaniakLogin.handleRedirectUri(url: url, sourceApplication: sourceApplication)
        
    }


}

