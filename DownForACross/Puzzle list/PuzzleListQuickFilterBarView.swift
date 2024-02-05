//
//  PuzzleListQuickFilterBarView.swift
//  DownForACross
//
//  Created by Justin Hill on 2/3/24.
//

import UIKit

protocol PuzzleListQuickFilterBarViewDelegate {
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedSizesDidChange: PuzzleListQuickFilterBarView.PuzzleSize)
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedWordFilterDidChange: String?)
}

class PuzzleListQuickFilterBarView: UIView {
    
    private var selectedWordFilterIndex: Int? {
        didSet {
            if let index = self.selectedWordFilterIndex {
                self.delegate?.filterBar(self, selectedWordFilterDidChange: self.wordFilters[index])
            } else {
                self.delegate?.filterBar(self, selectedWordFilterDidChange: nil)
            }
        }
    }
    var selectedWordFilter: String? {
        if let selectedWordFilterIndex {
            return self.wordFilters[selectedWordFilterIndex]
        } else {
            return nil
        }
    }
    
    private let wordFilters: [String] = [
        "NY Times",
        "LA Times",
        "The Crossword",
        "WSJ"
    ]
    
    lazy var wordFilterButtons = self.wordFilters.map({ term in
        var config = UIButton.Configuration.plain()
        config.title = term
        
        let button = UIButton(configuration: config)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(textFilterButtonTapped(_:)), for: .primaryActionTriggered)
        
        return button
    })
    
    enum PuzzleSize: Int, CaseIterable {
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
        
        var includeMinis: Bool {
            return [PuzzleSize.all, PuzzleSize.mini].contains(self)
        }
        
        var includeStandards: Bool {
            return [PuzzleSize.all, PuzzleSize.standard].contains(self)
        }
        
        var next: PuzzleSize {
            Self.allCases[(self.rawValue + 1) % Self.allCases.count]
        }
    }
    
    var delegate: PuzzleListQuickFilterBarViewDelegate?
    
    lazy var sizeSelectorButton: UIButton = UIButton(configuration: self.buttonConfigurationFor(puzzleSize: self.selectedPuzzleSize))
    let scrollView: UIScrollView = UIScrollView()
    var filterStackView: UIStackView!
    
    var selectedPuzzleSize: PuzzleSize = .all {
        didSet {
            self.sizeSelectorButton.configuration = self.buttonConfigurationFor(puzzleSize: self.selectedPuzzleSize)
            self.delegate?.filterBar(self, selectedSizesDidChange: self.selectedPuzzleSize)
        }
    }
    
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
        
        self.filterStackView = UIStackView(arrangedSubviews: self.wordFilterButtons)
        self.filterStackView.distribution = .fill
        
//        let spacer = UIView()
//        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
//        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
//        self.filterStackView.addArrangedSubview(spacer)
        
        self.scrollView.showsHorizontalScrollIndicator = false
        self.preservesSuperviewLayoutMargins = true
        self.scrollView.preservesSuperviewLayoutMargins = true
        self.filterStackView.preservesSuperviewLayoutMargins = true
        self.addSubview(self.sizeSelectorButton)
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.filterStackView)
        
        self.sizeSelectorButton.addAction(UIAction(handler: { _ in
            self.selectedPuzzleSize = self.selectedPuzzleSize.next
        }), for: .primaryActionTriggered)
        
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
            self.scrollView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            self.filterStackView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.filterStackView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.filterStackView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.filterStackView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
        ])
    }
    
    @objc func textFilterButtonTapped(_ sender: UIButton) {
        guard let index = self.wordFilterButtons.firstIndex(of: sender) else { return }
        if index == self.selectedWordFilterIndex {
            self.selectedWordFilterIndex = nil
        } else {
            self.selectedWordFilterIndex = index
        }
        
        self.wordFilterButtons.enumerated().forEach { index, button in
            if index == self.selectedWordFilterIndex {
                var newConfig = UIButton.Configuration.filled()
                newConfig.title = self.wordFilters[index]
                button.configuration = newConfig
            } else {
                var newConfig = UIButton.Configuration.plain()
                newConfig.title = self.wordFilters[index]
                button.configuration = newConfig
            }
        }
    }
    
    
}
