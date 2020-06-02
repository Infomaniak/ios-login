//
//  File.swift
//  
//
//  Created by Ambroise Decouttere on 02/06/2020.
//

import UIKit
import WebKit

class WebViewVC: UIViewController, WKUIDelegate {
    
//    var webView: WKWebView = {
//        print("INITIALIZED")
//        let webConfiguration = WKWebViewConfiguration()
//        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        webView.uiDelegate = self
////        webView.translatesAutoresizingMaskIntoConstraints = false
//        print("INITIALIZED")
//        return webView
//    }()
    
    var webView: WKWebView!
    
    
        
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        self.view.addSubview(webView)
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(webView)
        print("SETUP UI")
        
//        if #available(iOS 11.0, *) {
//            NSLayoutConstraint.activate([
//                webView.topAnchor
//                    .constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
//                webView.leftAnchor
//                    .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
//                webView.bottomAnchor
//                    .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
//                webView.rightAnchor
//                    .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor)
//            ])
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if(navigationAction.navigationType == .other) {
            if navigationAction.request.url != nil {
                //do what you need with url
                //self.delegate?.openURL(url: navigationAction.request.url!)
                print("CALLED")
                if InfomaniakLogin.handleRedirectUri(url: navigationAction.request.url!) {
                    print("OUI OUI OUI")
                }
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
