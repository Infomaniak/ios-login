//
//  File.swift
//
//
//  Created by Ambroise Decouttere on 02/06/2020.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView!
    var urlRequest: URLRequest!
    var redirectUri: String!
    var clearCookie: Bool!
    var navBarTitle: String?
    var navBarTitleColor: UIColor?
    var navBarColor: UIColor?
    var navBarButtonColor: UIColor?

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
    }


    func setupNavBar() {
        self.title = navBarTitle ?? "login.infomaniak.com"

        if #available(iOS 13.0, *) {
            let navigationAppaerance = UINavigationBarAppearance()
            navigationAppaerance.configureWithDefaultBackground()
            if navBarColor != nil {
                navigationAppaerance.backgroundColor = navBarColor!
            }
            if navBarTitleColor != nil {
                navigationAppaerance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarTitleColor!]
            }
            self.navigationController?.navigationBar.standardAppearance = navigationAppaerance
                        
        } else {
            if navBarColor != nil {
                self.navigationController?.navigationBar.backgroundColor = navBarColor
            }
            if navBarTitleColor != nil {
                self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarTitleColor!]
            }
        }
        let backButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonPressed))
        if navBarButtonColor != nil {
            backButton.tintColor = navBarButtonColor!
        }
        self.navigationItem.rightBarButtonItem = backButton
        
    }


    @objc func doneButtonPressed() {
        self.dismiss(animated: true) { }
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

}


