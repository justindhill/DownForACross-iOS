//
//  PuzzlePlayersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/28/24.
//

import UIKit

class PuzzlePlayersViewController: UIViewController {
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.preservesSuperviewLayoutMargins = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    lazy var inviteButton: UIButton = {
        let button = UIButton(configuration: .gray())
        button.configuration?.title = "Send invite"
        button.addTarget(self, action: #selector(inviteButtonTapped), for: .primaryActionTriggered)
        
        return button
    }()
    
    override func viewDidLoad() {
        self.view.addSubview(self.stackView)
        self.stackView.addArrangedSubview(self.inviteButton)
        
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor)
        ])
    }
    
    @objc func inviteButtonTapped() {
        let activityViewController = UIActivityViewController(activityItems: [URL(string: "https://downforacross.com")!], applicationActivities: nil)
        self.present(activityViewController, animated: true)
    }
    
}
