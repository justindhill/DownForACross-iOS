//
//  EmptyStateView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/6/24.
//

import UIKit

class EmptyStateView: UIView {
    
    let label: UILabel = UILabel()
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        
        self.activityIndicator.isHidden = false
        self.label.textColor = UIColor.secondaryLabel
        self.label.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [self.label, self.activityIndicator])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        self.label.font = UIFont.preferredFont(forTextStyle: .title2)
    }
    
}


