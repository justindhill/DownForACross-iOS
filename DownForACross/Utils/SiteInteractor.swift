//
//  SiteInteractor.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation
import WebKit

class SiteInteractor: NSObject {
    
    let timeout: TimeInterval = 10
    
    var session: URLSession = .shared
    var webViews: [WKWebView] = []
    var completionBlocks: [WKWebView: (WKWebView) -> Void] = [:]
    var timeoutTimers: [WKWebView: Timer] = [:]
    
    typealias GetUserCompletion = ((String?) -> Void)
    func getUserId(completion: @escaping GetUserCompletion) -> Void {
        var baseUrlComponents = Config.siteBaseURLComponents
        #if DFAC_LOCAL_SERVER
        baseUrlComponents.path = "/beta/play/397"
        #else
        baseUrlComponents.path = "/beta/play/31894"
        #endif
        
        let webView = WKWebView()
        webView.navigationDelegate = self
        completionBlocks[webView] = { webView in
            guard let url = webView.url,
                    url.pathComponents.count >= 3 &&
                    url.pathComponents[1] == "beta" &&
                    url.pathComponents[2] == "game" else { return }
            
            webView.evaluateJavaScript("window.gameComponent.user.id") { [weak self] result, error in
                completion(result as? String)
                self?.tearDownInteraction(webView: webView)
            }
        }
        webView.load(URLRequest(url: baseUrlComponents.url!))
    }
    
    func createGame(puzzleId: String, completion: @escaping (String?) -> Void) {
        var components = Config.siteBaseURLComponents
        components.path = "/beta/play/\(puzzleId)"
        
        let webView = WKWebView()
        webView.navigationDelegate = self
        
        let timer = Timer.scheduledTimer(withTimeInterval: self.timeout, repeats: false) { _ in
            completion(nil)
            self.tearDownInteraction(webView: webView)
        }
        
        self.timeoutTimers[webView] = timer
        self.completionBlocks[webView] = { [weak self] webView in
            guard let url = webView.url,
                    url.pathComponents.count >= 3 &&
                    url.pathComponents[1] == "beta" &&
                    url.pathComponents[2] == "game" else { return }
            completion(url.lastPathComponent)
            print(url.lastPathComponent)
            self?.tearDownInteraction(webView: webView)
        }
        webView.load(URLRequest(url: components.url!))
    }
    
    func tearDownInteraction(webView: WKWebView) {
        self.completionBlocks.removeValue(forKey: webView)
        self.timeoutTimers[webView]?.invalidate()
        self.timeoutTimers.removeValue(forKey: webView)
    }
    
}

extension SiteInteractor: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let completion = self.completionBlocks[webView] {
            completion(webView)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webview fail! \(webView.url?.absoluteString ?? "unknown url") \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("webview fail! \(webView.url?.absoluteString ?? "unknown url") \(error)")
    }
}
