//
//  File.swift
//
//
//  Created by Ambroise Decouttere on 02/06/2020.
//

import UIKit
import WebKit

class WebViewVC: UIViewController, WKUIDelegate {

    var webView: WKWebView!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
//        webView?.addObserver(self, forKeyPath: "URL", options: .new, context: nil)

    }

//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        if let url = change?[.newKey] as? URL {
//            if url.scheme == "com.infomaniak.auth" {
//                InfomaniakLogin.handleRedirectUri(url: url)
//            }
//        }
//    }
    


}


//MARK: - WKNavigationDelegate

extension WebViewVC: WKNavigationDelegate {

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
