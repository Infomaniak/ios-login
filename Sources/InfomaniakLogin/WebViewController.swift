
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
        self.title = "login.infomaniak.com"
        let backButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))
        self.navigationItem.rightBarButtonItem = backButton
    }


    @objc func doneButtonPressed() {
        self.dismiss(animated: true) { }
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        cleanCookies()
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
        if(navigationAction.navigationType == .formSubmitted) {
            if let urlScheme = navigationAction.request.url?.scheme {
                //do what you need with url
                if urlScheme == "com.infomaniak.auth" {

                    if InfomaniakLogin.webviewHandleRedirectUri(url: navigationAction.request.url!) {
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
        }
        decisionHandler(.allow)
    }

}


