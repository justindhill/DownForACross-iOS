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

    let itemSideLength: CGFloat = 44

    var selectedColor: UIColor {
        guard let indexPath = self.collectionView.indexPathsForSelectedItems?.first else {
            fatalError("There should always be a selected color")
        }
        
        return self.colors[indexPath.row]
    }

    override var intrinsicContentSize: CGSize {
        // the top margin includes the arrow area, but should be equal to the bottom
        var size = self.collectionView.collectionViewLayout.collectionViewContentSize
        size.height += (2 * self.layoutMargins.bottom)
        size.width += self.layoutMargins.left + self.layoutMargins.right
        return size
    }

    lazy var dataSource: UICollectionViewDiffableDataSource<Int, UIColor> = {
        UICollectionViewDiffableDataSource<Int, UIColor>(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, color in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorPickerView.reuseIdentifier, for: indexPath)
            cell.layer.cornerRadius = self.itemSideLength / 2
            cell.layer.masksToBounds = true
            cell.contentView.backgroundColor = color
            cell.layer.borderWidth = cell.isSelected ? 2 : 0
            return cell
        })
    }()
    
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.itemSize = CGSize(width: self.itemSideLength, height: self.itemSideLength)

        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: ColorPickerView.reuseIdentifier)
        view.isScrollEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsMultipleSelection = false
        view.delegate = self
        view.backgroundColor = .clear

        return view
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        self.collectionView.dataSource = self.dataSource
        self.addSubview(self.collectionView)
        
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
        ])
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, UIColor>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.colors, toSection: 0)
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    private var _lastCollectionViewSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()

        let size = self.collectionViewLayout.collectionViewContentSize
        if size != self._lastCollectionViewSize {
            _lastCollectionViewSize = size
            self.invalidateIntrinsicContentSize()
        }
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
