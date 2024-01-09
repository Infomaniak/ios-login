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

import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupDI()

        return true
    }

    // Needed if there is no SceneDelegate.swift file
    var window: UIWindow?

    func application(_ application: UIApplication,
                     open url: URL, sourceApplication:
                     String?, annotation: Any) -> Bool {
        let service = InjectService<InfomaniakLogin>().wrappedValue
        return service.handleRedirectUri(url: url)
    }

    func setupDI() {
        /// The `InfomaniakLoginable` interface hides the concrete type `InfomaniakLogin`
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakLoginable.self) { _, _ in
            let clientId = "9473D73C-C20F-4971-9E10-D957C563FA68"
            let redirectUri = "com.infomaniak.drive://oauth2redirect"
            let login = InfomaniakLogin(config: .init(clientId: clientId, redirectURI: redirectUri))
            return login
        })

        /// Chained resolution, the `InfomaniakTokenable` interface uses the `InfomaniakLogin` object as well
        SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakTokenable.self) { _, resolver in
            return try resolver.resolve(type: InfomaniakLoginable.self,
                                        forCustomTypeIdentifier: nil,
                                        factoryParameters: nil,
                                        resolver: resolver)
        })
    }
}
