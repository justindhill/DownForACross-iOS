//
//  QuickFiltersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 4/24/24.
//

import UIKit

class QuickFiltersViewController: UIViewController {

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = "Quick filters"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGroupedBackground
    }

}
