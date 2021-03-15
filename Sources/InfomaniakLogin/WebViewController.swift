//
//  WebViewController.swift
//  InfomaniakLogin
//
//  Created by Ambroise Decouttere on 02.06.2020.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {

    var clearCookie: Bool!
    var navBarButtonColor: UIColor?
    var navBarColor: UIColor?
    var navBarTitle: String?
    var navBarTitleColor: UIColor?
    var redirectUri: String!
    var urlRequest: URLRequest!
    var webView: WKWebView!

    let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?

    let maxLoadingTime = 20.0
    var timeOutMessage: String?
    var timer: Timer?


    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupProgressView()
        setupEstimatedProgressObserver()
        webView.load(urlRequest)
        timer = Timer.scheduledTimer(timeInterval: maxLoadingTime, target: self, selector: #selector(timeOutError), userInfo: nil, repeats: false)
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
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }

    func setupNavBar() {
        self.title = navBarTitle ?? "login.infomaniak.com"

        if #available(iOS 13.0, *) {
            let navigationAppaerance = UINavigationBarAppearance()
            navigationAppaerance.configureWithDefaultBackground()
            if let navBarColor = navBarColor {
                navigationAppaerance.backgroundColor = navBarColor
            }
            if let navBarTitleColor = navBarTitleColor {
                navigationAppaerance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarTitleColor]
            }
            self.navigationController?.navigationBar.standardAppearance = navigationAppaerance
        } else {
            if let navBarColor = navBarColor {
                self.navigationController?.navigationBar.backgroundColor = navBarColor
            }
            if let navBarTitleColor = navBarTitleColor {
                self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarTitleColor]
            }
        }

        let backButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.doneButtonPressed))
        if let navBarButtonColor = navBarButtonColor {
            backButton.tintColor = navBarButtonColor
        }
        self.navigationItem.leftBarButtonItem = backButton
    }

    @objc func doneButtonPressed() {
        self.dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if clearCookie {
            cleanCookies()
        }
    }

    func cleanCookies() {
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            for record in records {
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record]) { }
            }
        }
    }

    @objc func timeOutError() {
        let alertController = UIAlertController(title: timeOutMessage ?? "Page Not Loading !", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
}


//MARK: - WKNavigationDelegate

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

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let host = navigationAction.request.url?.host {
            if host.contains("login.infomaniak.com") || host.contains("oauth2redirect") {
                decisionHandler(.allow)
                return
            }
        }
        if let url = navigationAction.request.url?.absoluteString {
            if url.contains("www.google.com/recaptcha") {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if webView.url?.absoluteString.starts(with: redirectUri) ?? false {
            InfomaniakLogin.webviewHandleRedirectUri(url: webView.url!)
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



