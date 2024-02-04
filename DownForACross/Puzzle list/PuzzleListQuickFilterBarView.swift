//
//  PuzzleListQuickFilterBarView.swift
//  DownForACross
//
//  Created by Justin Hill on 2/3/24.
//

import UIKit

class PuzzleListQuickFilterBarView: UIView {
    
    let wordFilters: [String] = [
        "NY Times",
        "LA Times",
        "The Crossword",
        "WSJ"
    ]
    
    enum PuzzleSize: Int {
        case all
        case standard
        case mini
        
        var displayString: String {
            switch self {
                case .all: "All sizes"
                case .standard: "Standard"
                case .mini: "Mini"
            }
        }
    }
    
    lazy var sizeSelectorButton: UIButton = UIButton(configuration: self.buttonConfigurationFor(puzzleSize: .all))
    let scrollView: UIScrollView = UIScrollView()
    let filterStackView: UIStackView = UIStackView()
    
    func buttonConfigurationFor(puzzleSize: PuzzleSize) -> UIButton.Configuration {
        var config: UIButton.Configuration
        switch puzzleSize {
            case .all:
                config = .gray()
            case .standard, .mini:
                config = .filled()
        }
        
        config.title = puzzleSize.displayString
        return config
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        
        self.preservesSuperviewLayoutMargins = true
        self.scrollView.preservesSuperviewLayoutMargins = true
        self.filterStackView.preservesSuperviewLayoutMargins = true
        self.addSubview(self.sizeSelectorButton)
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.filterStackView)
        
        self.filterStackView.translatesAutoresizingMaskIntoConstraints = false
        self.sizeSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.filterStackView.axis = .horizontal
        
        NSLayoutConstraint.activate([
            self.sizeSelectorButton.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            self.sizeSelectorButton.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            self.sizeSelectorButton.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.sizeSelectorButton.trailingAnchor, constant: 8),
            self.scrollView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    
}
