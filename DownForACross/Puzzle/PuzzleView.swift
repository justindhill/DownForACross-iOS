//
//  PuzzleView.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit

protocol PuzzleViewDelegate: AnyObject {
    func puzzleView(_ puzzleView: PuzzleView, didEnterText text: String?, atCoordinates coordinates: CellCoordinates)
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToCoordinates coordinates: CellCoordinates)
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToClue: PuzzleView.ModelLocation?)
    
    func puzzleView(_ puzzleView: PuzzleView, referencesInClueAtClueIndex clueIndex: Int, direction: Direction) -> [PuzzleClues.ClueReference]
}

class PuzzleView: UIView {
    
    typealias Theme = UIColor.Puzzle
    typealias UserCursor = (coordinates: CellCoordinates, direction: Direction)
    typealias ModelLocation = (clueIndex: Int, sequenceIndex: Int, direction: Direction)
    typealias SequenceEntry = (cellNumber: Int, coordinates: CellCoordinates)
    
    enum Constant {
        static let otherPlayerCursorOpacity: CGFloat = 0.3
        static let wordBoundary: String = "."
    }
    
    weak var delegate: PuzzleViewDelegate?
    
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                self.setNeedsTextLayout()
            }
        }
    }
    
    override var bounds: CGRect {
        didSet {
            if bounds.size != oldValue.size {
                self.setNeedsTextLayout()
            }
        }
    }
    
    var isPlayerAttributionEnabled: Bool = false {
        didSet { self.setNeedsLayout() }
    }
    
    var userCursorColor: UIColor = .gray
    var isDarkMode: Bool { self.traitCollection.userInterfaceStyle == .dark }
    var isSolved: Bool = false
    var grid: [[String]]
    var circles: Set<Int>
    var acrossSequence: [SequenceEntry] = []
    var downSequence: [SequenceEntry] = []
    var acrossCellNumberToCoordinatesMap: [Int: CellCoordinates] = [:]
    var downCellNumberToCoordinatesMap: [Int: CellCoordinates] = [:]
    var solution: [[CellEntry?]] {
        didSet { self.setNeedsLayout() }
    }
    
    var cursors: [String: Cursor] {
        didSet { self.setNeedsLayout() }
    }
    
    var userCursor: UserCursor = (CellCoordinates(row: 0, cell: 0), .across) {
        didSet {
            if oldValue.coordinates != userCursor.coordinates {
                self.delegate?.puzzleView(self, userCursorDidMoveToCoordinates: userCursor.coordinates)
            }
            
            self.setNeedsLayout()
        }
    }
    
    lazy var tapGestureRecognizer = AccumulatingTapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerTriggered))
    
    var currentDepressedKeys = Set<UIKeyboardHIDUsage>()
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    lazy var userCursorLetterIndicatorLayer: CALayer = self.createActionlessLayer()
    lazy var userCursorWordIndicatorLayer: CALayer = self.createActionlessLayer()
    var backgroundView: UIView = UIView()
    var cursorIndicatorLayers: [String: CALayer] = [:]
    var numberTextLayers: [CATextLayer] = []
    var fillTextLayers: [DFACTextLayer] = []
    var separatorLayers: [CALayer] = []
    var referenceIndicatorLayers: [CALayer] = []
    
    var _needsTextLayout: Bool = true
    func setNeedsTextLayout() {
        _needsTextLayout = true
        self.setNeedsLayout()
    }
    
    private var isFirstLayout: Bool = true
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    var puzzleContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = Theme.background
        return view
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func didMoveToWindow() {
        if let window = self.window {
            let scale = window.screen.scale
            self.fillTextLayers.forEach({ $0.contentsScale = scale })
        }
    }
    
    init(puzzle: Puzzle) {
        self.grid = puzzle.grid
        self.solution = Array(repeating: Array(repeating: nil,
                                               count: puzzle.grid.columnCount),
                              count: self.grid.rowCount)
        self.cursors = [:]
        self.circles = Set(puzzle.circles)
        super.init(frame: .zero)
                
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.backgroundView)
        self.backgroundView.addSubview(self.puzzleContainerView)
        self.scrollView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    var cellCount: Int {
        guard self.grid.rowCount > 0 && self.grid.columnCount > 0 else { return 0 }
        return self.grid.rowCount * self.grid.columnCount
    }
    
    var nativePixelWidth: CGFloat {
        guard let screenScale = self.window?.screen.scale else { return 1 }
        return 1 / screenScale
    }
    
    var separatorWidth: CGFloat {
        let nativePixelWidth = self.nativePixelWidth
        if nativePixelWidth < 0.5 && self.grid.columnCount < 20 {
            return nativePixelWidth * 2
        } else {
            return nativePixelWidth
        }
    }
    
    var cellSideLength: CGFloat {
        guard self.cellCount > 0 else { return 0 }
        
        let unclippedWidth = self.frame.size.width / CGFloat(self.grid.columnCount)
        let clippedWidth = unclippedWidth - unclippedWidth.truncatingRemainder(dividingBy: self.nativePixelWidth)
        return clippedWidth
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.backgroundView.frame.size.width, 
                      height: self.backgroundView.frame.size.height)
    }
    
    override func layoutSubviews() {
        // cache these because apparently bridging to CGColor is really expensive
        let numberLayerColor = Theme.fillNormal.cgColor
        let textBorderColor = Theme.attributedBorder.cgColor
        let emptySpaceBackgroundColor = Theme.emptySpaceBackground.cgColor
        let clearBackgroundColor = UIColor.clear.cgColor
        let normalFillColor = self.isPlayerAttributionEnabled ? Theme.attributedFillNormal.cgColor : Theme.fillNormal.cgColor
        let correctFillColor = self.isPlayerAttributionEnabled ? Theme.attributedFillCorrect.cgColor : Theme.fillCorrect.cgColor
        let revealedFillColor = Theme.fillRevealed.cgColor
        let incorrectSlashColor = Theme.incorrectSlash.cgColor
        let separatorColor = Theme.separator.cgColor
        
        let cellSideLength = self.cellSideLength
        let separatorWidth = self.separatorWidth
        let letterIndicatorWidth = (cellSideLength * 0.07)
                
        self.puzzleContainerView.layer.borderWidth = separatorWidth
        self.puzzleContainerView.layer.borderColor = separatorColor
        self.backgroundView.backgroundColor = Theme.separator
        
        guard self.grid.rowCount > 0 && self.grid.columnCount > 0 else { return }

        self.scrollView.frame = self.bounds
            
        var unscaledPuzzleContainerFrame = CGRect(x: 0,
                                                  y: 0,
                                                  width: self.cellSideLength * CGFloat(self.grid.columnCount),
                                                  height: self.cellSideLength * CGFloat(self.grid.rowCount) +  separatorWidth)
        var borderWidth = (self.frame.size.width - unscaledPuzzleContainerFrame.size.width) / 2
        borderWidth = borderWidth - borderWidth.truncatingRemainder(dividingBy: self.nativePixelWidth)
        unscaledPuzzleContainerFrame.origin = CGPoint(x: borderWidth, y: borderWidth)
            
        self.backgroundView.frame = CGRect(x: 0,
                                           y: 0,
                                           width: self.frame.size.width,
                                           height: unscaledPuzzleContainerFrame.size.height + (2 * borderWidth))
            .applying(CGAffineTransform(scaleX: self.scrollView.zoomScale,
                                        y: self.scrollView.zoomScale))
        
        self.puzzleContainerView.frame = unscaledPuzzleContainerFrame

        
        if self.scrollView.contentSize == .zero {
            self.scrollView.contentSize = self.intrinsicContentSize
        }
        
        let cellCount = self.cellCount
        self.scrollView.maximumZoomScale = max((50 / self.cellSideLength), 1)
                
        let sizingFont = UIFont.systemFont(ofSize: 12)
        let pointToCapHeight = sizingFont.pointSize / sizingFont.capHeight
        let baseFillFont = UIFont.systemFont(ofSize: ceil((cellSideLength * 0.5) * pointToCapHeight), weight: .medium)
        let numberFont = UIFont.systemFont(ofSize: ceil(baseFillFont.pointSize / 3.2))
        let numberPadding: CGFloat = cellSideLength / 20
        
        // user cursor word indicator
        if self.userCursorWordIndicatorLayer.superlayer == nil {
            self.puzzleContainerView.layer.addSublayer(self.userCursorWordIndicatorLayer)
            self.userCursorWordIndicatorLayer.backgroundColor = self.userCursorColor.withAlphaComponent(0.2).cgColor
        }
        
        let oldWordIndicatorFrame = self.userCursorWordIndicatorLayer.frame
        self.userCursorWordIndicatorLayer.frame = self.boundingBoxOfCurrentWord(cellSideLength: cellSideLength)
        
        let separatorCount = self.grid.rowCount * self.grid.columnCount - 2
        self.updateTextLayerCount(target: cellCount, font: baseFillFont)
        self.updateSeparatorCount(target: separatorCount)

        DFACTextLayer.incorrectSlashColor = incorrectSlashColor
        DFACTextLayer.circleColor = Theme.circle.cgColor
        DFACTextLayer.updateDrawingPaths(sideLength: cellSideLength, separatorWidth: separatorWidth)

        var textLayerIndex = 0
        var cellNumber = 1
        
        var acrossSequence: [SequenceEntry] = []
        var downSequence: [SequenceEntry] = []
        var acrossCellNumberToCoordinatesMap: [Int: CellCoordinates] = [:]
        var downCellNumberToCoordinatesMap: [Int: CellCoordinates] = [:]
        var userIdToCGColorMap: [String: CGColor] = [:]
        if self.isPlayerAttributionEnabled {
            userIdToCGColorMap = self.cursors.mapValues(\.player.color.cgColor)
        }

        for (rowIndex, row) in self.grid.enumerated() {
            for (itemIndex, item) in row.enumerated() {
                let layer = self.fillTextLayers[textLayerIndex]
                let coords = CellCoordinates(row: rowIndex, cell: itemIndex)

                let ltrCellIndex = (rowIndex * row.count) + itemIndex
                layer.drawsCircle = self.circles.contains(ltrCellIndex)
                if self._needsTextLayout {
                    if self.itemRequiresNumberLabel(item, atRow: rowIndex, index: itemIndex) {
                        let numberTextLayer: CATextLayer
                        if cellNumber < self.numberTextLayers.count + 1 {
                            numberTextLayer = self.numberTextLayers[cellNumber - 1]
                        } else {
                            numberTextLayer = self.createNumberTextLayer()
                        }
                        numberTextLayer.font = numberFont
                        numberTextLayer.fontSize = numberFont.pointSize
                        numberTextLayer.string = "\(cellNumber)"
                        numberTextLayer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength + separatorWidth + numberPadding,
                                                       y: CGFloat(rowIndex) * cellSideLength + numberPadding,
                                                       width: cellSideLength,
                                                       height: numberFont.lineHeight)
                        
                        if  // at the beginning or the previous one is a word boundary
                            (coords.isFirstRow || (self.grid[coords.previous(.down)] == Constant.wordBoundary)) &&
                            // not at the end and next one isn't a word boundary
                            (coords.row < self.grid.rowCount - 1 && self.grid[coords.next(.down)] != Constant.wordBoundary) {

                            downSequence.append((cellNumber, coords))
                            downCellNumberToCoordinatesMap[cellNumber] = coords
                        }
                        
                        if  // previous one is a word boundary or the beginning of the row
                            (coords.isFirstColumn || self.grid[coords.previous(.across)] == Constant.wordBoundary) &&
                            // not at the end and next one isn't a word boundary
                            (coords.cell < self.grid[rowIndex].count - 1 && self.grid[coords.next(.across)] != Constant.wordBoundary) {

                            acrossSequence.append((cellNumber, coords))
                            acrossCellNumberToCoordinatesMap[cellNumber] = coords
                        }
                        
                        cellNumber += 1
                    }
                    
                    layer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength,
                                         y: CGFloat(rowIndex) * cellSideLength,
                                         width: cellSideLength,
                                         height: cellSideLength).adjusted(forSeparatorWidth: separatorWidth)
                }

                layer.drawsIncorrectSlash = false

                if item == Constant.wordBoundary {
                    layer.backgroundColor = emptySpaceBackgroundColor
                    layer.string = nil
                } else {
                    layer.backgroundColor = clearBackgroundColor
                    
                    if let solutionEntry = self.solution[rowIndex][itemIndex] {
                        layer.string = solutionEntry.value
                        if solutionEntry.value.count > 1 {
                            let scaleFactor = pow(CGFloat(0.8), CGFloat(solutionEntry.value.count))
                            let scaledFont = baseFillFont.withSize(baseFillFont.pointSize * scaleFactor)
                            layer.font = scaledFont
                            layer.fontSize = scaledFont.pointSize
                        } else {
                            layer.font = baseFillFont
                            layer.fontSize = baseFillFont.pointSize
                        }

                        if let correctness = solutionEntry.correctness {
                            switch correctness {
                                case .correct:
                                    layer.foregroundColor = correctFillColor
                                case .revealed:
                                    layer.foregroundColor = revealedFillColor
                                case .incorrect:
                                    layer.foregroundColor = normalFillColor
                                    layer.drawsIncorrectSlash = true
                            }
                        } else {
                            layer.foregroundColor = normalFillColor
                        }

                        if self.isPlayerAttributionEnabled {
                            layer.textStrokeColor = textBorderColor
                            layer.textStrokeWidth = 2

                            if let playerColor = userIdToCGColorMap[solutionEntry.userId] {
                                layer.backgroundColor = playerColor
                            } else {
                                layer.backgroundColor = self.userCursorColor.cgColor
                            }
                        } else {
                            layer.textStrokeColor = nil
                        }
                    } else {
                        layer.font = baseFillFont
                        layer.fontSize = baseFillFont.pointSize
                        layer.string = nil
                    }
                }
                
                textLayerIndex += 1
            }
        }
        
        if self._needsTextLayout {
            self.acrossSequence = acrossSequence
            self.downSequence = downSequence
            self.acrossCellNumberToCoordinatesMap = acrossCellNumberToCoordinatesMap
            self.downCellNumberToCoordinatesMap = downCellNumberToCoordinatesMap
            
            if self.isFirstLayout, let firstAcrossCoordinates = acrossSequence.first?.coordinates {
                self.userCursor.coordinates = firstAcrossCoordinates
                if self.currentWordIsFullAndPotentiallyCorrect() {
                    self.advanceUserCursorToNextWord()
                }
            }
        }
        
        // separators
        for i in 0..<self.grid.rowCount - 1 {
            let horizontal = self.separatorLayers[i]
            let offset = CGFloat(i + 1) * cellSideLength
            horizontal.frame = CGRect(x: 0, y: offset, width: self.frame.size.width, height: separatorWidth)
            horizontal.backgroundColor = separatorColor
        }
        for i in (self.grid.rowCount)..<self.grid.rowCount + self.grid.columnCount - 1 {
            let vertical = self.separatorLayers[i]
            let offset = CGFloat(i - self.grid.rowCount + 1) * cellSideLength
            let newHeight = self.puzzleContainerView.frame.size.height * self.scrollView.zoomScale
            vertical.frame = CGRect(x: offset, y: 0, width: separatorWidth, height: newHeight)
            vertical.backgroundColor = separatorColor
        }
        
        // cursors
        self.syncCursorLayerCount()
        for (userId, cursor) in self.cursors {
            guard let layer = self.cursorIndicatorLayers[userId] else { return }

            layer.backgroundColor = cursor.player.color.withAlphaComponent(Constant.otherPlayerCursorOpacity).cgColor
            layer.frame = CGRect(x: CGFloat(cursor.coordinates.cell) * cellSideLength,
                                 y: CGFloat(cursor.coordinates.row) * cellSideLength,
                                 width: cellSideLength,
                                 height: cellSideLength).adjusted(forSeparatorWidth: separatorWidth)
        }
        
        // user cursor letter indicator
        if self.userCursorLetterIndicatorLayer.superlayer == nil {
            self.puzzleContainerView.layer.addSublayer(self.userCursorLetterIndicatorLayer)
            self.userCursorLetterIndicatorLayer.borderWidth = letterIndicatorWidth
        }

        if self.isPlayerAttributionEnabled && self.solution[self.userCursor.coordinates] != nil {
            self.userCursorLetterIndicatorLayer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        } else {
            self.userCursorLetterIndicatorLayer.borderColor = self.userCursorColor.cgColor
        }
        self.userCursorLetterIndicatorLayer.frame = CGRect(x: CGFloat(self.userCursor.coordinates.cell) * cellSideLength,
                                                           y: CGFloat(self.userCursor.coordinates.row) * cellSideLength,
                                                           width: cellSideLength,
                                                           height: cellSideLength).adjusted(forSeparatorWidth: separatorWidth)
        
        if oldWordIndicatorFrame != self.userCursorWordIndicatorLayer.frame {
            guard let modelLocation = self.findCurrentClueCellNumber() else {
                self.delegate?.puzzleView(self, userCursorDidMoveToClue: nil)
                return
            }
            
            self.delegate?.puzzleView(self, userCursorDidMoveToClue: modelLocation)
            if let references = self.delegate?.puzzleView(self, referencesInClueAtClueIndex: modelLocation.clueIndex, direction: modelLocation.direction) {
                self.updateReferenceIndicatorCount(target: references.count)
                for (index, reference) in references.enumerated() {
                    let coordinates: CellCoordinates?
                    switch reference.direction {
                        case .across:
                            coordinates = self.acrossCellNumberToCoordinatesMap[reference.number]
                        case .down:
                            coordinates = self.downCellNumberToCoordinatesMap[reference.number]
                    }
                    
                    if let coordinates {
                        let frame = self.boundingBoxOfWord(atCoordinates: coordinates, direction: reference.direction, cellSideLength: cellSideLength)
                        self.referenceIndicatorLayers[index].frame = frame
                    }
                }
            }
        }
        
        self.numberTextLayers.forEach({ $0.foregroundColor = numberLayerColor })

        // don't cache this color because this code path is rarely hit
        self.referenceIndicatorLayers.forEach({ $0.backgroundColor = Theme.referenceBackground.cgColor })
        
        self.isFirstLayout = false
        self._needsTextLayout = false
    }
    
    func itemRequiresNumberLabel(_ item: String?, atRow row: Int, index: Int) -> Bool {
        let dueToFirstCell = (row == 0 || index == 0) && item != Constant.wordBoundary
        let dueToDown = 
            // previous row is an empty space
            (row > 0 && self.grid[row - 1][index] == Constant.wordBoundary) &&
            // this row is not an empty space
            item != Constant.wordBoundary &&
            // next row is not an empty space
            (row < self.grid.rowCount - 1 && self.grid[row + 1][index] != Constant.wordBoundary)
        let dueToAcross =
            // previous column is an empty space
            (index > 0 && self.grid[row][index - 1] == Constant.wordBoundary) &&
            // this column is not an empty space
            item != Constant.wordBoundary &&
            // next column is not an empty space
            (index < self.grid[row].count - 1 && self.grid[row][index + 1] != Constant.wordBoundary)
        
        return dueToFirstCell || dueToDown || dueToAcross
    }
    
    func createNumberTextLayer() -> CATextLayer {
        let layer = CATextLayer()
        layer.contentsScale = self.window?.screen.scale ?? 1
        layer.actions = [
            "contents": NSNull()
        ]
        
        self.numberTextLayers.append(layer)
        self.puzzleContainerView.layer.addSublayer(layer)
        return layer
    }
    
    func syncCursorLayerCount() {
        for userId in self.cursors.keys {
            if self.cursorIndicatorLayers[userId] == nil {
                let layer = self.createActionlessLayer()
                self.cursorIndicatorLayers[userId] = layer
                self.puzzleContainerView.layer.insertSublayer(layer, at: 0)
            }
        }
    }
    
    func updateTextLayerCount(target: Int, font: UIFont) {
        while self.fillTextLayers.count != target {
            if self.fillTextLayers.count < target {
                let layer = DFACTextLayer()
                layer.font = font
                layer.fontSize = font.pointSize
                layer.contentsScale = self.window?.screen.scale ?? 1
                layer.alignmentMode = .center
                layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                layer.actions = [
                    "contents": NSNull(),
                    "foregroundColor": NSNull(),
                    "backgroundColor": NSNull(),
                    "font": NSNull(),
                    "fontSize": NSNull()
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
                self.puzzleContainerView.layer.addSublayer(layer)
                self.separatorLayers.append(layer)
            } else {
                self.separatorLayers.removeLast().removeFromSuperlayer()
            }
        }
    }
    
    func updateReferenceIndicatorCount(target: Int) {
        while self.referenceIndicatorLayers.count != target {
            if self.referenceIndicatorLayers.count < target {
                let layer = self.createActionlessLayer()
                
                self.puzzleContainerView.layer.insertSublayer(layer, at: 0)
                self.referenceIndicatorLayers.append(layer)
            } else {
                self.referenceIndicatorLayers.removeLast().removeFromSuperlayer()
            }
        }
    }
    
    func createActionlessLayer() -> CALayer {
        let layer = CALayer()
        layer.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "size": NSNull(),
            "borderColor": NSNull()
        ]
        
        return layer
    }
    
    func advanceUserCursorToNextLetter() {
        let current = self.userCursor.coordinates
        func nextCandidate(after lastCandidate: CellCoordinates) -> CellCoordinates {
            switch self.userCursor.direction {
                case .across:
                    if lastCandidate.cell + 1 >= self.grid.columnCount {
                        return current
                    }
                case .down:
                    if lastCandidate.row + 1 >= self.grid.rowCount {
                        return current
                    }
            }

            return lastCandidate.next(self.userCursor.direction)
        }
        
        var candidate = nextCandidate(after: current)
        if candidate == current {
            return
        }
        
        while self.grid[candidate] == Constant.wordBoundary || self.solution[candidate]?.isWritable == false {
            candidate = nextCandidate(after: candidate)
            if candidate == current {
                return
            }
        }
        
        self.userCursor = UserCursor(coordinates: candidate, direction: self.userCursor.direction)
    }
    
    func retreatUserCursorToPreviousLetterIfNotAtNonemptyEdge() {
        let current = self.userCursor.coordinates
        func nextCandidate(after lastCandidate: CellCoordinates) -> CellCoordinates {
            switch self.userCursor.direction {
                case .across:
                    if lastCandidate.cell - 1 < 0 ||
                        lastCandidate.cell == self.solution[lastCandidate.row].count - 1 && self.solution[lastCandidate] != nil {
                        return current
                    }
                case .down:
                    if lastCandidate.row - 1 < 0 ||
                        lastCandidate.row == self.solution.count - 1 && self.solution[lastCandidate]?.value != nil {
                        return current
                    }
            }

            return lastCandidate.previous(self.userCursor.direction)
        }
        
        
        var candidate = nextCandidate(after: current)
        
        while self.grid[candidate] == Constant.wordBoundary || self.solution[candidate]?.isWritable == false {
            candidate = nextCandidate(after: candidate)
            if candidate == current {
                return
            }
        }
        
        self.userCursor = UserCursor(coordinates: candidate, direction: self.userCursor.direction)
    }
    
    func advanceUserCursorToNextWord() {
        let wordExtent = self.findCurrentWordExtent()
        switch self.userCursor.direction {
            case .across:
                let firstLetterCoordinates = CellCoordinates(row: self.userCursor.coordinates.row, cell: wordExtent.location)
                let newIndex: Int
                if let currentIndex = self.acrossSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) {
                    newIndex = (currentIndex + 1) % self.acrossSequence.count
                } else {
                    newIndex = 0
                }
                
                // rollover
                if newIndex == 0 {
                    self.toggleDirection()
                    self.userCursor.coordinates = self.downSequence[newIndex].coordinates
                } else {
                    self.userCursor.coordinates = self.acrossSequence[newIndex].coordinates
                }
            case .down:
                let firstLetterCoordinates = CellCoordinates(row: wordExtent.location, cell: self.userCursor.coordinates.cell)
                let newIndex: Int
                if let currentIndex = self.downSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) {
                    newIndex = (currentIndex + 1) % self.downSequence.count
                } else {
                    newIndex = 0
                }

                // rollover
                if newIndex == 0 {
                    self.toggleDirection()
                    self.userCursor.coordinates = self.acrossSequence[newIndex].coordinates
                } else {
                    self.userCursor.coordinates = self.downSequence[newIndex].coordinates
                }
        }
        
        let isFullAndPotentiallyCorrect = self.currentWordIsFullAndPotentiallyCorrect()
        self.advanceToAppropriateCellIfNecessary(isCurrentWordFullAndPotentiallyCorrect: isFullAndPotentiallyCorrect)
    }
    
    func advanceToAppropriateCellIfNecessary(isCurrentWordFullAndPotentiallyCorrect: Bool) {
        if !self.isSolved {
            if isCurrentWordFullAndPotentiallyCorrect {
                self.advanceUserCursorToNextWord()
            } else if solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell]?.isWritable == false {
                self.advanceUserCursorToNextLetter()
            }
        }
    }
    
    func currentWordIsFullAndPotentiallyCorrect() -> Bool {
        return self.findCurrentWordCellCoordinates().reduce(into: true) { partialResult, coords in
            let value = self.solution[coords]
            partialResult = partialResult && value != nil && value?.isWritable == false
        }
    }
    
    func moveUserCursorToWord(atSequenceIndex sequenceIndex: Int, direction: Direction) {
        let entry: SequenceEntry
        switch direction {
            case .across:
                entry = self.acrossSequence[sequenceIndex]
            case .down:
                entry = self.downSequence[sequenceIndex]
        }
        
        self.userCursor = UserCursor(coordinates: entry.coordinates, direction: direction)
    }
    
    func retreatUserCursorToPreviousWord(trailingEdge: Bool = false) {
        let wordExtent = self.findCurrentWordExtent()
        var rollover = false
        switch self.userCursor.direction {
            case .across:
                let firstLetterCoordinates = CellCoordinates(row: self.userCursor.coordinates.row, cell: wordExtent.location)
                guard let currentIndex = self.acrossSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) else { return }
                let newIndex = (currentIndex == 0) ? self.acrossSequence.count - 1 : currentIndex - 1
                rollover = (newIndex == self.acrossSequence.count - 1)
                let newCoordinates = rollover ? self.downSequence.last! : self.acrossSequence[newIndex]
                self.userCursor.coordinates = newCoordinates.coordinates
            case .down:
                let firstLetterCoordinates = CellCoordinates(row: wordExtent.location, cell: self.userCursor.coordinates.cell)
                guard let currentIndex = self.downSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) else { return }
                let newIndex = (currentIndex == 0) ? self.downSequence.count - 1 : currentIndex - 1
                rollover = (newIndex == self.downSequence.count - 1)
                let newCoordinates = rollover ? self.acrossSequence.last! : self.downSequence[newIndex]
                self.userCursor.coordinates = newCoordinates.coordinates
        }
        
        if rollover {
            self.toggleDirection()
        }
                
        if !self.isSolved && self.currentWordIsFullAndPotentiallyCorrect() {
            self.retreatUserCursorToPreviousWord(trailingEdge: trailingEdge)
        } else if trailingEdge {
            let newWordExtent = self.findCurrentWordCellCoordinates()
            if let lastNonCorrectCell = newWordExtent.reversed().first(where: {
                (self.solution[$0]?.isWritable ?? true) == true }
            ) {
                self.userCursor.coordinates = lastNonCorrectCell
            }
        } else if solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell]?.isWritable == false {
            self.advanceUserCursorToNextLetter()
        }
    }
    
    func isUserCursorAtTrailingWordBoundary() -> Bool {
        let coordinates = self.userCursor.coordinates
        switch self.userCursor.direction {
            case .across:
                // cells in the word after the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.cell > coordinates.cell })

                return
                    // at end of row
                    coordinates.cell == self.solution[coordinates.row].count - 1 ||
                    // at the end of the word
                    self.grid[coordinates.next(.across)] == Constant.wordBoundary ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1]?.isWritable == false })
                    
            case .down:
                // cells in the word after the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.row > coordinates.row })
                
                return
                    // at end of column
                    coordinates.row == self.grid.rowCount - 1 ||
                    // at the end of the word
                    self.grid[coordinates.next(.down)] == Constant.wordBoundary ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1]?.isWritable == false })
        }
    }
    
    func isUserCursorAtLeadingWordBoundary() -> Bool {
        let coordinates = self.userCursor.coordinates
        switch self.userCursor.direction {
            case .across:
                // cells in the word before the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.cell < coordinates.cell })

                return
                    // at beginning of row
                    coordinates.isFirstColumn ||
                    // at the beginning of the word
                    self.grid[coordinates.previous(.across)] == Constant.wordBoundary ||
                    // cells of the word before this one are checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1]?.isWritable == false })
                    
            case .down:
                // cells in the word after the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.row < coordinates.row })
                
                return
                    // at beginning of column
                    coordinates.isFirstRow ||
                    // at the beginning of the word
                    self.grid[coordinates.previous(.down)] == Constant.wordBoundary ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1]?.isWritable == false })
        }
    }
    
    func findCurrentWordCellCoordinates() -> [CellCoordinates] {
        let extent = self.findCurrentWordExtent()
        return (extent.location..<(extent.location + extent.length)).map { index in
            switch self.userCursor.direction {
                case .across:
                    CellCoordinates(row: self.userCursor.coordinates.row, cell: index)
                case .down:
                    CellCoordinates(row: index, cell: self.userCursor.coordinates.cell)
            }
        }
    }

    func findAllLetterCellCoordinates() -> [CellCoordinates] {
        var coordinates: [CellCoordinates] = []
        for (rowIndex, rowContent) in self.grid.enumerated() {
            for (cellIndex, cellContent) in rowContent.enumerated() {
                if cellContent != Constant.wordBoundary {
                    coordinates.append(CellCoordinates(row: rowIndex, cell: cellIndex))
                }
            }
        }

        return coordinates
    }

    func findCurrentWordExtent() -> NSRange {
        return self.findExtentOfWord(atCoordinates: self.userCursor.coordinates, direction: self.userCursor.direction)
    }
    
    func boundingBoxOfCurrentWord(cellSideLength: CGFloat) -> CGRect {
        return self.boundingBoxOfWord(atCoordinates: self.userCursor.coordinates, 
                                      direction: self.userCursor.direction,
                                      cellSideLength: cellSideLength)
    }
    
    func boundingBoxOfWord(atCoordinates coordinates: CellCoordinates, direction: Direction, cellSideLength: CGFloat) -> CGRect {
        let wordExtent = self.findExtentOfWord(atCoordinates: coordinates, direction: direction)
        switch direction {
            case .across:
                return CGRect(
                    x: cellSideLength * CGFloat(wordExtent.location),
                    y: cellSideLength * CGFloat(coordinates.row),
                    width: cellSideLength * CGFloat(wordExtent.length),
                    height: cellSideLength)
            case .down:
                return CGRect(
                    x: cellSideLength * CGFloat(coordinates.cell),
                    y: cellSideLength * CGFloat(wordExtent.location),
                    width: cellSideLength,
                    height: cellSideLength * CGFloat(wordExtent.length))
        }
    }
    
    func findExtentOfWord(atCoordinates coordinates: CellCoordinates, direction: Direction) -> NSRange {
        var firstLetterIndex = direction == .across ? coordinates.cell : coordinates.row
        var lastLetterIndex = firstLetterIndex
        var firstLetterFound = false
        var lastLetterFound = false
        
        while !(firstLetterFound && lastLetterFound) {
            if !firstLetterFound {
                if firstLetterIndex - 1 < 0 {
                    firstLetterFound = true
                } else {
                    switch direction {
                        case .across:
                            let candidateCell = self.grid[coordinates.row][firstLetterIndex - 1]
                            if candidateCell == Constant.wordBoundary {
                                firstLetterFound = true
                            } else {
                                firstLetterIndex -= 1
                            }
                        case .down:
                            let candidateCell = self.grid[firstLetterIndex - 1][coordinates.cell]
                            if candidateCell == Constant.wordBoundary {
                                firstLetterFound = true
                            } else {
                                firstLetterIndex -= 1
                            }
                    }
                }
            }
            
            if !lastLetterFound {
                if direction == .across && lastLetterIndex + 1 > self.grid.columnCount - 1 {
                    lastLetterFound = true
                } else if direction == .down && lastLetterIndex + 1 > self.grid.rowCount - 1 {
                    lastLetterFound = true
                } else {
                    switch direction {
                        case .across:
                            let candidateCell = self.grid[coordinates.row][lastLetterIndex + 1]
                            if candidateCell == Constant.wordBoundary {
                                lastLetterFound = true
                            } else {
                                lastLetterIndex += 1
                            }
                        case .down:
                            let candidateCell = self.grid[lastLetterIndex + 1][coordinates.cell]
                            if candidateCell == Constant.wordBoundary {
                                lastLetterFound = true
                            } else {
                                lastLetterIndex += 1
                            }
                    }
                }
            }
        }
        
        let range = NSRange(location: firstLetterIndex, length: lastLetterIndex - firstLetterIndex + 1)
        return range
    }
    
    @objc func tapGestureRecognizerTriggered(_ tap: UITapGestureRecognizer) {
        let pointCoords = tap.location(in: self.puzzleContainerView)
        
        guard self.puzzleContainerView.bounds.contains(pointCoords) else {
            return
        }
        
        let sideLength = self.cellSideLength
        let cellCoords = CellCoordinates(row: Int(pointCoords.y / sideLength),
                                         cell: Int(pointCoords.x / sideLength))
        
        let item = self.grid[cellCoords]

        if item == Constant.wordBoundary {
            return
        } else if cellCoords == self.userCursor.coordinates {
            self.toggleDirection()
            if self.findCurrentWordExtent().length == 1 {
                self.toggleDirection()
            }
        } else {
            self.userCursor = UserCursor(coordinates: cellCoords, direction: self.userCursor.direction)
            if self.findCurrentWordExtent().length == 1 {
                self.toggleDirection()
            }
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        self.currentDepressedKeys.formUnion(presses.compactMap({ $0.key?.keyCode }))
        if self.currentDepressedKeys.count == 1 {
            switch self.currentDepressedKeys.first {
                case .keyboardRightArrow:
                    if self.userCursor.direction == .down {
                        self.toggleDirection()
                    } else {
                        self.advanceUserCursorToNextLetter()
                    }
                case .keyboardLeftArrow:
                    if self.userCursor.direction == .down {
                        self.toggleDirection()
                    } else {
                        self.retreatUserCursorToPreviousLetterIfNotAtNonemptyEdge()
                    }
                case .keyboardDownArrow:
                    if self.userCursor.direction == .across {
                        self.toggleDirection()
                    } else {
                        self.advanceUserCursorToNextLetter()
                    }
                case .keyboardUpArrow:
                    if self.userCursor.direction == .across {
                        self.toggleDirection()
                    } else {
                        self.retreatUserCursorToPreviousLetterIfNotAtNonemptyEdge()
                    }
                case .keyboardTab:
                    self.advanceUserCursorToNextWord()
                default:
                    super.pressesBegan(presses, with: event)
            }
        } else if self.currentDepressedKeys.count == 2 {
            if self.currentDepressedKeys.contains(.keyboardTab) {
                if self.currentDepressedKeys.contains(.keyboardLeftShift) || self.currentDepressedKeys.contains(.keyboardRightShift) {
                    self.retreatUserCursorToPreviousWord()
                }
            } else {
                super.pressesBegan(presses, with: event)
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }
    
    func findCurrentClueCellNumber() -> ModelLocation? {
        let wordExtent = self.findCurrentWordExtent()
        
        let sequenceIndex: Int?
        var currentEntry: SequenceEntry? = nil
        switch self.userCursor.direction {
            case .across:
                let firstLetterCoordinates = CellCoordinates(row: self.userCursor.coordinates.row, cell: wordExtent.location)
                sequenceIndex = self.acrossSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates })
                if let sequenceIndex {
                    currentEntry = self.acrossSequence[sequenceIndex]
                }
            case .down:
                let firstLetterCoordinates = CellCoordinates(row: wordExtent.location, cell: self.userCursor.coordinates.cell)
                sequenceIndex = self.downSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates })
                if let sequenceIndex {
                    currentEntry = self.downSequence[sequenceIndex]
                }
        }
        
        if let sequenceIndex, let currentEntry {
            return ModelLocation(clueIndex: currentEntry.cellNumber, sequenceIndex: sequenceIndex, direction: self.userCursor.direction)
        } else {
            return nil
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        presses.compactMap({ $0.key?.keyCode }).forEach({ self.currentDepressedKeys.remove($0) })
    }
    
    func toggleDirection() {
        self.userCursor = UserCursor(coordinates: self.userCursor.coordinates, direction: self.userCursor.direction.opposite)
    }
    
}

extension PuzzleView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.backgroundView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let window = self.window else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.fillTextLayers.forEach({ $0.contentsScale = window.screen.scale * scale })
        self.numberTextLayers.forEach({ $0.contentsScale = window.screen.scale * scale })
        CATransaction.commit()
        
        self.setNeedsLayout()
    }
}

extension CGRect {
    
    func adjusted(forSeparatorWidth separatorWidth: CGFloat) -> CGRect {
        var adjusted = self
        adjusted.size.width += separatorWidth
        adjusted.size.height += separatorWidth
        return adjusted.insetBy(dx: separatorWidth, dy: separatorWidth)
    }
    
}

extension PuzzleView: UIKeyInput {
    
    var hasText: Bool {
        true
    }
    
    func insertText(_ text: String) {
        
        func advance() {
            if !self.isSolved {
                if self.isUserCursorAtTrailingWordBoundary() {
                    self.advanceUserCursorToNextWord()
                } else {
                    self.advanceUserCursorToNextLetter()
                }
            }
        }

        // take only the first letter
        var character = text[text.startIndex]

        if text == " " {
            self.toggleDirection()
            if self.findCurrentWordExtent().length == 1 {
                self.toggleDirection()
            }
            return
        } else if text == "\n" || self.solution[self.userCursor.coordinates]?.isWritable == false {
            advance()
        } else {
            var newValue: String
            var shouldAdvance: Bool = false
            if character.isUppercase || character == "/" || character == "?" {
                var actualCharacter = character
                if character == "?" {
                    actualCharacter = "/"
                }

                // uppercase input from the keyboard is handled as rebus input
                newValue = self.solution[self.userCursor.coordinates]?.value ?? ""
                newValue.append(String(actualCharacter).uppercased())
            } else {
                newValue = String(character).uppercased()
                shouldAdvance = true
            }

            self.delegate?.puzzleView(self, didEnterText: newValue, atCoordinates: self.userCursor.coordinates)
            if shouldAdvance {
                advance()
            }
        }
    }
    
    func deleteBackward() {
        if let currentCellEntry = self.solution[self.userCursor.coordinates], currentCellEntry.isWritable {
            self.delegate?.puzzleView(self, didEnterText: nil, atCoordinates: self.userCursor.coordinates)
            return
        }
        
        if self.isUserCursorAtLeadingWordBoundary() {
            self.retreatUserCursorToPreviousWord(trailingEdge: true)
        } else {
            self.retreatUserCursorToPreviousLetterIfNotAtNonemptyEdge()
        }
        
        self.delegate?.puzzleView(self, didEnterText: nil, atCoordinates: self.userCursor.coordinates)
    }
    
}
