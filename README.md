# InfomaniakLogin


Library to simplify login process with Infomaniak oauth 2.0 protocol

  
## Install

  On your Xcode project, go to --- File > Swift Packages > Add Package Dependency... ---.
  Then you can add this link : `git@gitlab.infomaniak.ch:infomaniak/mobile-app/ios/libraries/login.git`
  Or you can also use the URL : https://gitlab.infomaniak.ch/infomaniak/mobile-app/ios/libraries/login.git

  

## Use


### If your project have a SceneDelegate.swift file

First you can `ìmport InfomaniakLogin` at the top of the file.

In SceneDelegate.swift, add this function :

````
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
        // Handle URL
        InfomaniakLogin.handleRedirectUri(url: url)
    }
}

````

  
### If your project doesn't have a SceneDelegate.swift file

First you can `ìmport InfomaniakLogin` at the top of the file.
And initialise a UIWindow variable inside the AppDelegate class :
````var window: UIWindow?````

Then you can add this function inside the class `AppDelegate` :

````
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    return InfomaniakLogin.handleRedirectUri(url: url)
}
````

  


### Final part

You can now use it where you want by adding the InfomaniakLoginDelegate protocol to the class who need it :

````

func didCompleteLoginWith(code: String, verifier: String) {
    InfomaniakLogin.getApiTokenUsing(code: code, codeVerifier: verifier) { (token, error) in }
}

````

And you can finally use the login fonction for example with a button by writing :

````
@IBAction func login(_ sender: UIButton) {
    InfomaniakLogin.loginFrom(viewController: self, delegate: self, clientId: clientId, redirectUri: redirectUri)
}
````
With these arguments :

- `clientId` : The client ID of the app
- `redirectUri` : The redirection URL after a successful login (in order to handle the codes) 

