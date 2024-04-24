//
//  NavigationSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 4/24/24.
//

import UIKit

protocol NavigationSettingViewHandler: AnyObject {
    func navigationViewDidNavigateWithMode(mode: SettingsViewController.Mode)
}

class NavigationSettingView: BaseSettingView {
    
    weak var navigationHandler: NavigationSettingViewHandler?
    var mode: SettingsViewController.Mode?
    var handler: (() -> Void)?

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init(title: String,
         details: String?,
         mode: SettingsViewController.Mode,
         navigationHandler: NavigationSettingViewHandler) {
        self.mode = mode
        self.navigationHandler = navigationHandler
        super.init(title: title, details: details, accessoryView: Self.createAccessoryView())
        self.addTapRecognizer()
    }

    init(title: String, details: String?, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, details: details, accessoryView: Self.createAccessoryView())
        self.addTapRecognizer()
    }

    func addTapRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap))
        self.addGestureRecognizer(tap)
    }

    @objc func didReceiveTap() {
        self.handler?()

        guard let mode = self.mode, let navigationHandler = self.navigationHandler else { return }
        navigationHandler.navigationViewDidNavigateWithMode(mode: mode)
    }

    class func createAccessoryView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        imageView.isUserInteractionEnabled = false
        imageView.tintColor = .secondaryLabel
        return imageView
    }

}
