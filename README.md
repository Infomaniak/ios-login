# InfomaniakLogin

Library to simplify login process with Infomaniak OAuth 2.0 protocol

## Installation

1. In your Xcode project, go to: File > Swift Packages > Add Package Dependency…
2. Enter the package URL: `git@github.com:Infomaniak/ios-login.git` or `https://github.com/Infomaniak/ios-login.git`

## Usage

### Shared setup
1. Add `import InfomaniakLogin` and `import InfomaniakDI` at the top of your AppDelegate
2. Add this method and call it asap in the `func application(didFinishLaunchingWithOptions:)`
```swift
    func setupDI() {
        do {
            /// The `InfomaniakLoginable` interface hides the concrete type `InfomaniakLogin`
            try SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakLoginable.self) { _, _ in
                let clientId = "9473D73C-C20F-4971-9E10-D957C563FA68"
                let redirectUri = "com.infomaniak.drive://oauth2redirect"
                let login = InfomaniakLogin(clientId: clientId, redirectUri: redirectUri)
                return login
            })
            
            /// Chained resolution, the `InfomaniakTokenable` interface uses the `InfomaniakLogin` object as well
            try SimpleResolver.sharedResolver.store(factory: Factory(type: InfomaniakTokenable.self) { _, resolver in
                return try resolver.resolve(type: InfomaniakLoginable.self,
                                            forCustomTypeIdentifier: nil,
                                            factoryParameters: nil,
                                            resolver: resolver)
            })
        } catch {
            fatalError("unexpected \(error)")
        }
    }
```

### With SFSafariViewController

**If your project has a `SceneDelegate.swift` file:**
1. Add `import InfomaniakLogin` and `import InfomaniakDI` at the top of the file
2. Add this property `@InjectService var loginService: InfomaniakLoginable`
3. Add this method:
```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
        // Handle URL
        _ = loginService.handleRedirectUri(url: url)
    }
}
```

**If your project doesn't have a `SceneDelegate.swift` file:**
1. Go to your AppDelegate
2. Initialise a `UIWindow` variable inside your AppDelegate:
```swift
var window: UIWindow?
```
3. Add this method inside your AppDelegate:
```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    let service = InjectService<InfomaniakLogin>().wrappedValue
    return service.handleRedirectUri(url: url)
}
```

**Final part:**

You can now use it where you want by adding the injected property like so `@InjectService var loginService: InfomaniakLoginable`
and adding the `InfomaniakLoginDelegate` protocol to the class who needs it:

````swift
func didCompleteLoginWith(code: String, verifier: String) {
    loginService.getApiTokenUsing(code: code, codeVerifier: verifier) { (token, error) in 
        // Save the token
    }
}

func didFailLoginWith(error: Error) {
    // Handle the error
}
````

And you can finally use the login fonction, for example with a button, by writing:

````swift
@IBAction func login(_ sender: UIButton) {
    loginService.loginFrom(viewController: self, delegate: self, clientId: clientId, redirectUri: redirectUri)
}
````

With these arguments:
- `clientId`: The client ID of the app
- `redirectUri`: The redirection URL after a successful login (in order to handle the codes)

### With WKWebView

First, add `import InfomaniakLogin` at the top of the file.

Also add `import InfomaniakDI`

Then ad the injected service property like so `@InjectService var loginService: InfomaniakLoginable`

You can now use it where you want by adding the `InfomaniakLoginDelegate` protocol to the class who needs it:

````swift
func didCompleteLoginWith(code: String, verifier: String) {
    InfomaniakLogin.getApiTokenUsing(code: code, codeVerifier: verifier) { (token, error) in 
        // Save the token
    }
}

func didFailLoginWith(error: Error) {
    // Handle the error
}
````

And you can finally use the login function, for example with a button, by writing:

````swift
@IBAction func login(_ sender: UIButton) {
    InfomaniakLogin.webviewLoginFrom(viewController: self, delegate: self, clientId: clientId, redirectUri: redirectUri)
}
````

With these arguments:
- `clientId`: The client ID of the app
- `redirectUri`: The redirection URL after a successful login (in order to handle the codes)

But if you are using the Web View method, you can also use this method:

````swift
InfomaniakLogin.setupWebviewNavbar(title: nil, color: .red, clearCookie: true)
````

With these arguments:
- `title`: The title that will be shown in the navigation bar
- `color`: The color of the navigation bar
- `clearCookie`:
    - If `true`, the cookie will be deleted when the Web View is closed
    - If `false`, the cookie won't be deleted when the Web View is closed

## License

    Copyright 2023 Infomaniak
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
