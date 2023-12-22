//
//  SiteInteractor.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation
import WebKit

class SiteInteractor: NSObject {
    
    var webViews: [WKWebView] = []
    var completionBlocks: [WKWebView: (WKWebView) -> Void] = [:]
    var loadCounts: [WKWebView: Int] = [:]
    
    typealias GetUserCompletion = ((String?) -> Void)
    func getUserId(completion: @escaping GetUserCompletion) -> Void {
        let webView = WKWebView()
        webView.navigationDelegate = self
        completionBlocks[webView] = { webView in
            webView.evaluateJavaScript("window.gameComponent.user.id") { result, error in
                completion(result as? String)
            }            
        }
        self.loadCounts[webView] = 1
        webView.load(URLRequest(url: URL(string: "https://downforacross.com/beta/play/31894")!))
    }
    
}

extension SiteInteractor: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if var loadCount = self.loadCounts[webView] {
            loadCount += 1
            print(loadCount)
            self.loadCounts[webView] = loadCount
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if var loadCount = self.loadCounts[webView], let completion = self.completionBlocks[webView] {
            print(loadCount)
            loadCount -= 1
            completion(webView)

            if loadCount <= 0 {
                completion(webView)
                self.loadCounts.removeValue(forKey: webView)
            } else {
                self.loadCounts[webView] = loadCount
            }
        }
    }
}
