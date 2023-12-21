//
//  PuzzleView.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit

class PuzzleView: UIControl {
    
    var puzzleGrid: [[String?]]
    var solution: [[String?]]
    
    var numberTextLayers: [CATextLayer] = []
    var fillTextLayers: [CATextLayer] = []
    var separatorLayers: [CALayer] = []
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    var puzzleContainerView: UIView = UIView()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func didMoveToWindow() {
        if let window = self.window {
            let scale = window.screen.scale
            self.fillTextLayers.forEach({ $0.contentsScale = scale })
        }
    }
    
    init(puzzleGrid: [[String?]]) {
        self.puzzleGrid = puzzleGrid
        self.solution = Array(repeating: Array(repeating: nil,
                                               count: puzzleGrid[0].count),
                              count: puzzleGrid.count)
        super.init(frame: .zero)
        
        self.puzzleContainerView.layer.borderWidth = 0.5
        self.puzzleContainerView.layer.borderColor = UIColor.systemGray2.cgColor
        
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.puzzleContainerView)
        
    }
    
    override func layoutSubviews() {
        guard self.puzzleGrid.count > 0 && self.puzzleGrid[0].count > 0 else { return }
        
        self.scrollView.frame = self.bounds
        self.puzzleContainerView.frame = self.bounds
        
        let cellCount = self.puzzleGrid.count * self.puzzleGrid[0].count
        let cellSideLength = self.frame.size.width / CGFloat(self.puzzleGrid[0].count)
        
        let sizingFont = UIFont.systemFont(ofSize: 12)
        let pointToCapHeight = sizingFont.pointSize / sizingFont.capHeight
        let baseFillFont = UIFont.systemFont(ofSize: ceil((cellSideLength * 0.4) * pointToCapHeight))
        let numberFont = UIFont.systemFont(ofSize: ceil(baseFillFont.pointSize / 2.8))
        let numberPadding: CGFloat = cellSideLength / 20
        
        let separatorCount = 2 * self.puzzleGrid.count - 2
        self.updateTextLayerCount(target: cellCount, font: baseFillFont)
        self.updateSeparatorCount(target: separatorCount)
        
        var textLayerIndex = 0
        var cellNumber = 1
        for (rowIndex, row) in self.puzzleGrid.enumerated() {
            for (itemIndex, item) in row.enumerated() {
                let layer = self.fillTextLayers[textLayerIndex]
                
                if self.itemRequiresNumberLabel(item, atRow: rowIndex, index: itemIndex) {
                    let numberTextLayer: CATextLayer
                    if cellNumber < self.numberTextLayers.count {
                        numberTextLayer = self.numberTextLayers[cellNumber - 1]
                    } else {
                        numberTextLayer = self.createNumberTextLayer()
                    }
                    numberTextLayer.font = numberFont
                    numberTextLayer.fontSize = numberFont.pointSize
                    numberTextLayer.string = "\(cellNumber)"
                    numberTextLayer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength + numberPadding,
                                                   y: CGFloat(rowIndex) * cellSideLength + numberPadding,
                                                   width: cellSideLength,
                                                   height: numberFont.lineHeight)
                    cellNumber += 1
                }
                
                if let item {
                    if item == "." {
                        layer.backgroundColor = UIColor.black.cgColor
                        layer.string = nil
                        layer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength,
                                             y: CGFloat(rowIndex) * cellSideLength,
                                             width: cellSideLength,
                                             height: cellSideLength)
                    } else {
                        let fillFont: UIFont
                        if item.count > 1 {
                            let scaleFactor = pow(CGFloat(0.86), CGFloat(item.count))
                            fillFont = baseFillFont.withSize(baseFillFont.pointSize * scaleFactor)
                        } else {
                            fillFont = baseFillFont
                        }
                        
                        layer.font = fillFont
                        layer.fontSize = fillFont.pointSize
                        
                        let ascenderAdjustment = (fillFont.lineHeight - fillFont.capHeight + fillFont.descender - fillFont.leading)
                        let yCenterOffset = (cellSideLength - fillFont.capHeight) / 2
                        layer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength,
                                             y: CGFloat(rowIndex) * cellSideLength + yCenterOffset - ascenderAdjustment + 0.5,
                                             width: cellSideLength,
                                             height: fillFont.lineHeight)
                        layer.backgroundColor = UIColor.clear.cgColor
                        layer.string = item
                    }
                } else {
                    layer.backgroundColor = UIColor.clear.cgColor
                    layer.string = nil
                    layer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength,
                                         y: CGFloat(rowIndex) * cellSideLength,
                                         width: cellSideLength,
                                         height: cellSideLength)
                }
                
                textLayerIndex += 1
            }
        }
        
        for i in 0..<self.puzzleGrid.count - 1 {
            let splitCount = separatorCount / 2
            let horizontal = self.separatorLayers[i]
            let vertical = self.separatorLayers[splitCount + i]
            let offset = CGFloat(i + 1) * cellSideLength
            horizontal.frame = CGRect(x: 0, y: offset, width: self.frame.size.width, height: 0.5)
            vertical.frame = CGRect(x: offset, y: 0, width: 0.5, height: self.frame.size.height)
        }
    }
    
    func itemRequiresNumberLabel(_ item: String?, atRow row: Int, index: Int) -> Bool {
        return (row == 0 || index == 0) && item != "." ||
               (row > 0 && self.puzzleGrid[row - 1][index] == ".") && item != "." ||
               (index > 0 && self.puzzleGrid[row][index - 1] == ".") && item != "."
    }
    
    func createNumberTextLayer() -> CATextLayer {
        let layer = CATextLayer()
        layer.foregroundColor = UIColor.darkText.cgColor
        layer.contentsScale = self.window?.screen.scale ?? 1
        layer.actions = [
            "contents": NSNull()
        ]
        
        self.numberTextLayers.append(layer)
        self.puzzleContainerView.layer.addSublayer(layer)
        return layer
    }
    
    func updateTextLayerCount(target: Int, font: UIFont) {
        while self.fillTextLayers.count != target {
            if self.fillTextLayers.count < target {
                let layer = CATextLayer()
                layer.font = font
                layer.fontSize = font.pointSize
                layer.foregroundColor = UIColor.black.cgColor
                layer.contentsScale = self.window?.screen.scale ?? 1
                layer.alignmentMode = .center
                layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                layer.actions = [
                    "contents": NSNull()
                ]
                
                self.puzzleContainerView.layer.addSublayer(layer)
                self.fillTextLayers.append(layer)
            } else {
                self.fillTextLayers.removeLast().removeFromSuperlayer()
            }
        }
    }
    
    func updateSeparatorCount(target: Int) {
        while self.separatorLayers.count != target {
            if self.separatorLayers.count < target {
                let layer = CALayer()
                layer.backgroundColor = UIColor.systemGray2.cgColor
                self.puzzleContainerView.layer.addSublayer(layer)
                self.separatorLayers.append(layer)
            } else {
                self.separatorLayers.removeLast().removeFromSuperlayer()
            }
        }
    }
    
}

extension PuzzleView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.puzzleContainerView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let window = self.window else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.fillTextLayers.forEach({ $0.contentsScale = window.screen.scale * scale })
        self.numberTextLayers.forEach({ $0.contentsScale = window.screen.scale * scale })
        CATransaction.commit()
    }
}
