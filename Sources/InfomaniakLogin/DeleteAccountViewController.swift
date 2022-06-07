//
//  DeleteAccountViewController.swift
//  
//
//  Created by Valentin Perignon on 03/06/2022.
//

import UIKit
import WebKit

public protocol DeleteAccountDelegate: AnyObject {
    func didCompleteDeleteAccount()
    func didFailDeleteAccount(context: [String: Any]?)
}

public class DeleteAccountViewController: UIViewController {
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    public var navBarColor: UIColor?
    public var navBarButtonColor: UIColor?

    private var progressObserver: NSKeyValueObservation?
    private var accountDeleted = false

    public weak var delegate: DeleteAccountDelegate?
    public var accessToken: String?

    public override func loadView() {
        super.loadView()
        setUpWebview()
        setupNavBar()
        setupProgressView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if let url = Constants.autologinUrl(to: Constants.DELETEACCOUNT_URL) {
            if let accessToken = accessToken {
                var request = URLRequest(url: url)
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                webView.load(request)
            } else {
                delegate?.didFailDeleteAccount(context: nil)
                dismiss(animated: true)
            }
        } else {
            delegate?.didFailDeleteAccount(context: ["URL" : "nil"])
            dismiss(animated: true)
        }
    }

    public static func instantiateInViewController(delegate: DeleteAccountDelegate? = nil, accessToken: String, navBarColor: UIColor? = nil, navBarButtonColor: UIColor? = nil) -> UINavigationController {
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
        } else {
            if let navBarColor = navBarColor {
                self.navigationController?.navigationBar.backgroundColor = navBarColor
            }
        }

        let backButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.close))
        if let navBarButtonColor = navBarButtonColor {
            backButton.tintColor = navBarButtonColor
        }
        self.navigationItem.leftBarButtonItem = backButton
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
            guard let newValue = value.newValue else { return }
            self?.progressView.isHidden = newValue == 1
            self?.progressView.setProgress(Float(newValue), animated: true)
        }
    }

    private func setUpWebview() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view = webView
    }

    @objc func close() {
        self.dismiss(animated: true)
    }
}

extension DeleteAccountViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            if urlString.starts(with: "https://login.infomaniak.com") {
                decisionHandler(.allow)
                dismiss(animated: true)
                if !accountDeleted {
                    delegate?.didCompleteDeleteAccount()
                    accountDeleted = true
                }
                return
            }
            if urlString.contains("infomaniak.com") {
                decisionHandler(.allow)
                return
            }
        }

        decisionHandler(.cancel)
        delegate?.didFailDeleteAccount(context: nil)
        dismiss(animated: true)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
            decisionHandler(.allow)
            return
        }

        if statusCode == 200 {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            let context: [String: Any] = [
                "URL": navigationResponse.response.url?.absoluteString ?? "",
                "Status code": statusCode
            ]
            delegate?.didFailDeleteAccount(context: context)
            dismiss(animated: true)
        }
    }


    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.didFailDeleteAccount(context: ["Error": error.localizedDescription])
        dismiss(animated: true)
    }
}
