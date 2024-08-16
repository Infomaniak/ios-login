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

#if canImport(UIKit)
import InfomaniakDI
import UIKit
import WebKit

public protocol DeleteAccountDelegate: AnyObject {
    func didCompleteDeleteAccount()
    func didFailDeleteAccount(error: InfomaniakLoginError)
}

public class DeleteAccountViewController: UIViewController {
    @LazyInjectService var infomaniakLogin: InfomaniakLoginable

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    public var navBarColor: UIColor?
    public var navBarButtonColor: UIColor?

    private var progressObserver: NSKeyValueObservation?
    private var accountDeleted = false

    public weak var delegate: DeleteAccountDelegate?
    public var accessToken: String?

    override public func loadView() {
        super.loadView()
        setupWebView()
        setupNavBar()
        setupProgressView()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if let url = Constants.autologinUrl(to: Constants.deleteAccountURL) {
            if let accessToken = accessToken {
                var request = URLRequest(url: url)
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                webView.load(request)
            } else {
                delegate?.didFailDeleteAccount(error: .invalidAccessToken(accessToken))
                dismiss(animated: true)
            }
        } else {
            delegate?.didFailDeleteAccount(error: .invalidUrl)
            dismiss(animated: true)
        }
    }

    public static func instantiateInViewController(
        delegate: DeleteAccountDelegate? = nil,
        accessToken: String?,
        navBarColor: UIColor? = nil,
        navBarButtonColor: UIColor? = nil
    ) -> UINavigationController {
        let deleteAccountViewController = DeleteAccountViewController()
        deleteAccountViewController.delegate = delegate
        deleteAccountViewController.accessToken = accessToken
        deleteAccountViewController.navBarColor = navBarColor
        deleteAccountViewController.navBarButtonColor = navBarButtonColor

        let navigationController = UINavigationController(rootViewController: deleteAccountViewController)
        return navigationController
    }

    private func setupNavBar() {
        if #available(iOS 13.0, *) {
            let navigationAppearance = UINavigationBarAppearance()
            navigationAppearance.configureWithDefaultBackground()
            if let navBarColor = navBarColor {
                navigationAppearance.backgroundColor = navBarColor
            }
            self.navigationController?.navigationBar.standardAppearance = navigationAppearance
        } else if let navBarColor = navBarColor {
            navigationController?.navigationBar.backgroundColor = navBarColor
        }

        let backButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close))
        if let navBarButtonColor = navBarButtonColor {
            backButton.tintColor = navBarButtonColor
        }
        navigationItem.leftBarButtonItem = backButton
    }

    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(progressView)

        progressView.isHidden = true

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])

        progressObserver = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, value in
            Task { @MainActor [weak self] in
                guard let newValue = value.newValue else { return }
                self?.progressView.isHidden = newValue == 1
                self?.progressView.setProgress(Float(newValue), animated: true)
            }
        }
    }

    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view = webView
    }

    @objc func close() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension DeleteAccountViewController: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            if url.host == infomaniakLogin.config.loginURL.host {
                decisionHandler(.allow)
                dismiss(animated: true)
                if !accountDeleted {
                    delegate?.didCompleteDeleteAccount()
                    accountDeleted = true
                }
                return
            }
            // Sometimes login redirects to about:blank
            if urlString.contains("infomaniak.com") || urlString.contains("about:blank") {
                decisionHandler(.allow)
                return
            }
        }

        decisionHandler(.cancel)
        delegate?.didFailDeleteAccount(error: .navigationCancelled(nil, nil))
        dismiss(animated: true)
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @MainActor (WKNavigationResponsePolicy) -> Void
    ) {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
            decisionHandler(.allow)
            return
        }

        if statusCode == 200 {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            delegate?.didFailDeleteAccount(error: .navigationCancelled(statusCode, navigationResponse.response.url))
            dismiss(animated: true)
        }
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.didFailDeleteAccount(error: .navigationFailed(error))
        dismiss(animated: true)
    }
}
#endif
