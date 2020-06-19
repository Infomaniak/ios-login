//
//  File.swift
//
//
//  Created by Ambroise Decouttere on 02/06/2020.
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

    let maxLoadingTime = 20.0
    var progress: UIActivityIndicatorView!
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
        webView.load(urlRequest)
        timer = Timer.scheduledTimer(timeInterval: maxLoadingTime, target: self, selector: #selector(timeOutError), userInfo: nil, repeats: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if progress == nil {
            progress = UIActivityIndicatorView(style: .whiteLarge)
            progress.center = view.center
            progress.color = UIColor.gray
            progress.hidesWhenStopped = true
            progress.startAnimating()
            view.addSubview(progress)
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

        let backButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonPressed))
        if navBarButtonColor = navBarButtonColor {
            backButton.tintColor = navBarButtonColor
        }
        self.navigationItem.rightBarButtonItem = backButton
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
        progress.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progress.stopAnimating()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        timer?.invalidate()
    }

}



