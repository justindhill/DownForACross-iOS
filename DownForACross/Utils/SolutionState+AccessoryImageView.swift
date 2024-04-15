//
//  SolutionState+AccessoryImageView.swift
//  DownForACross
//
//  Created by Justin Hill on 4/15/24.
//

import UIKit

extension GameClient.SolutionState {

    func createAccessoryImageView() -> UIImageView? {
        let imageView = UIImageView()
        imageView.frame.size = CGSize(width: 20, height: 20)
        imageView.tintColor = .secondaryLabel
        switch self {
            case .incomplete, .incorrect:
                imageView.image = UIImage(systemName: "circle.dotted")
            case .correct:
                imageView.image = UIImage(systemName: "checkmark.circle.fill")
            case .empty:
                return nil
        }

        return imageView
    }

}
