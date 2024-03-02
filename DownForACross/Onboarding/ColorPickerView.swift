//
//  ColorPickerView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/1/24.
//

import UIKit

class ColorPickerView: UIControl {
    
    static var reuseIdentifier: String = "ReuseIdentifier"
    var colors: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemPurple,
        .systemCyan,
        .systemMint,
        .systemTeal,
        .systemIndigo,
        .systemBrown
    ]
    
    var selectedColor: UIColor {
        guard let indexPath = self.collectionView.indexPathsForSelectedItems?.first else {
            fatalError("There should always be a selected color")
        }
        
        return self.colors[indexPath.row]
    }
    
    var _intrinsicContentSize: CGSize = .zero {
        didSet {
            if _intrinsicContentSize != oldValue {
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    override var intrinsicContentSize: CGSize {
        return _intrinsicContentSize
    }
    
    lazy var dataSource: UICollectionViewDiffableDataSource<Int, UIColor> = {
        UICollectionViewDiffableDataSource<Int, UIColor>(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, color in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorPickerView.reuseIdentifier, for: indexPath)
            cell.layer.cornerRadius = 12
            cell.layer.cornerCurve = .continuous
            cell.layer.masksToBounds = true
            cell.contentView.backgroundColor = color
            cell.layer.borderWidth = cell.isSelected ? 2 : 0
            return cell
        })
    }()
    
    let collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: ColorPickerView.reuseIdentifier)
        view.isScrollEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsMultipleSelection = false
        view.delegate = self
        
        return view
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        self.collectionView.dataSource = self.dataSource
        self.addSubview(self.collectionView)
        
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, UIColor>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.colors, toSection: 0)
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self._intrinsicContentSize = self.collectionViewLayout.collectionViewContentSize
    }
    
    func setSelectedColorToMatchingColorIfPossible(_ color: UIColor) {
        let index = self.colors.firstIndex(of: color) ?? 0
        let indexPath = IndexPath(row: index, section: 0)
        
        self.collectionView.selectItem(at: indexPath,
                                       animated: false,
                                       scrollPosition: .left)
        self.collectionView(self.collectionView, didSelectItemAt: indexPath)
    }
    
}

extension ColorPickerView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.sendActions(for: .valueChanged)
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        cell.layer.borderColor = UIColor.darkGray.cgColor
        cell.layer.borderWidth = 2
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        cell.layer.borderColor = UIColor.darkGray.cgColor
        cell.layer.borderWidth = 0
    }
    
}
