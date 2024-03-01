//
//  LaunchInterstitialViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 3/1/24.
//

import UIKit

class LaunchInterstitialViewController: UIViewController {
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = "Setting up a few things..."
        
        return label
    }()
    
    override func viewDidLoad() {
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.activityIndicator)
        self.view.addSubview(self.label)
        self.view.backgroundColor = .systemBackground
        
        NSLayoutConstraint.activate([
            self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.label.topAnchor.constraint(equalTo: self.activityIndicator.bottomAnchor, constant: 8),
            self.label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
        
        self.activityIndicator.startAnimating()
    }
}
