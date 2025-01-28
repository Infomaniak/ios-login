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

class WebViewController: UIViewController, WKUIDelegate {
    @LazyInjectService private var infomaniakLogin: InfomaniakLoginable

    private let clearCookie: Bool
    private let redirectUri: String
    private let urlRequest: URLRequest

    var navBarButtonColor: UIColor?
    var navBarColor: UIColor?
    var navBarTitle: String?
    var navBarTitleColor: UIColor?

    var timeOutMessage: String?
    var timer: Timer?

    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        return webView
    }()

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?

    private let maxLoadingTime = 20.0

    init(clearCookie: Bool, redirectUri: String, urlRequest: URLRequest) {
        self.clearCookie = clearCookie
        self.redirectUri = redirectUri
        self.urlRequest = urlRequest
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupProgressView()
        setupEstimatedProgressObserver()
        webView.load(urlRequest)
        timer = Timer.scheduledTimer(timeInterval: maxLoadingTime,
                                     target: self,
                                     selector: #selector(timeOutError),
                                     userInfo: nil,
                                     repeats: false)
    }

    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        progressView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(progressView)

        progressView.isHidden = true

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),

            progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])
    }

    private func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor [weak self] in
                self?.progressView.progress = Float(webView.estimatedProgress)
            }
        }
    }

    func setupNavBar() {
        title = navBarTitle ?? "login.infomaniak.com"

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithDefaultBackground()
        if let navBarColor = navBarColor {
            navigationAppearance.backgroundColor = navBarColor
        }
        if let navBarTitleColor = navBarTitleColor {
            navigationAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarTitleColor]
        }
        navigationController?.navigationBar.standardAppearance = navigationAppearance

        let backButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(doneButtonPressed))
        if let navBarButtonColor = navBarButtonColor {
            backButton.tintColor = navBarButtonColor
        }
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func doneButtonPressed() {
        dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if clearCookie {
            cleanCookies()
        }
    }

    func cleanCookies() {
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            for record in records {
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record]) {}
            }
        }
    }

    @objc func timeOutError() {
        let alertController = UIAlertController(
            title: timeOutMessage ?? "Page Not Loading !",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        if progressView.isHidden {
            progressView.isHidden = false
        }
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 1.0
                       })
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @MainActor (WKNavigationActionPolicy) -> Swift.Void
    ) {
        if let host = navigationAction.request.url?.host,
           let configHost = urlRequest.url?.host {
            if host.contains(configHost) || host.contains("oauth2redirect") {
                decisionHandler(.allow)
                return
            }

            // We are trying to navigate to somewhere else than login but still on the infomaniak host. (eg. manager)
            if host.hasSuffix("infomaniak.com") {
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if webView.url?.absoluteString.starts(with: redirectUri) ?? false {
            _ = infomaniakLogin.webviewHandleRedirectUri(url: webView.url!)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 0.0
                       },
                       completion: { isFinished in
                           self.progressView.isHidden = isFinished
                       })
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        timer?.invalidate()
    }
}
#endif
