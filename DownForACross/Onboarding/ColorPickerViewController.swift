//
//  ColorPickerViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 4/4/24.
//

import UIKit

class ColorPickerViewController: UIViewController {

    override func loadView() {
        self.view = ColorPickerView()
    }

    var colorPickerView: ColorPickerView { self.view as! ColorPickerView }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.delegate = self
        self.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        self.view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // setting this more than once during presentation makes it freak out
        let contentSize = self.colorPickerView.intrinsicContentSize
        if self.preferredContentSize.height == 0 {
            self.preferredContentSize = contentSize
        }
    }

}

extension ColorPickerViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}
