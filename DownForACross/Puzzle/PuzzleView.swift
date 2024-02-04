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
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToClueIndex clueIndex: Int, sequenceIndex: Int, direction: Direction)
}

class PuzzleView: UIView {

    typealias UserCursor = (coordinates: CellCoordinates, direction: Direction)
    typealias ModelLocation = (clueIndex: Int, sequenceIndex: Int, direction: Direction)
    typealias SequenceEntry = (cellNumber: Int, coordinates: CellCoordinates)
    
    enum Constant {
        static let otherPlayerCursorOpacity: CGFloat = 0.3
    }
    
    weak var delegate: PuzzleViewDelegate?
    
    var puzzleGrid: [[String?]]
    var acrossSequence: [SequenceEntry] = []
    var downSequence: [SequenceEntry] = []
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
    
    lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerTriggered))
    
    var currentDepressedKeys = Set<UIKeyboardHIDUsage>()
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var userCursorLetterIndicatorLayer: CALayer = CALayer()
    var userCursorWordIndicatorLayer: CALayer = CALayer()
    var cursorIndicatorLayers: [String: CALayer] = [:]
    var numberTextLayers: [CATextLayer] = []
    var fillTextLayers: [CATextLayer] = []
    var separatorLayers: [CALayer] = []
    
    private var isFirstLayout: Bool = true
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .always
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
        self.cursors = [:]
        super.init(frame: .zero)
        
        self.puzzleContainerView.layer.borderWidth = 0.5
        self.puzzleContainerView.layer.borderColor = UIColor.systemGray2.cgColor
        
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.puzzleContainerView)
        self.scrollView.addGestureRecognizer(self.tapGestureRecognizer)
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = 5
    }
    
    var cellCount: Int {
        guard self.puzzleGrid.count > 0 && self.puzzleGrid[0].count > 0 else { return 0}
        return self.puzzleGrid.count * self.puzzleGrid[0].count
    }
    
    var cellSideLength: CGFloat {
        guard self.cellCount > 0 else { return 0 }
        return self.frame.size.width / CGFloat(self.puzzleGrid[0].count)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.frame.size.width, height: self.cellSideLength * CGFloat(self.puzzleGrid.count))
    }
    
    override func layoutSubviews() {
        guard self.puzzleGrid.count > 0 && self.puzzleGrid[0].count > 0 else { return }
        
        self.scrollView.frame = self.bounds
        self.puzzleContainerView.frame = CGRect(origin: .zero, size: self.intrinsicContentSize)
            .applying(CGAffineTransform(scaleX: self.scrollView.zoomScale,
                                        y: self.scrollView.zoomScale))
        
        let cellCount = self.cellCount
        let cellSideLength = self.cellSideLength
        
        let sizingFont = UIFont.systemFont(ofSize: 12)
        let pointToCapHeight = sizingFont.pointSize / sizingFont.capHeight
        let baseFillFont = UIFont.systemFont(ofSize: ceil((cellSideLength * 0.4) * pointToCapHeight))
        let numberFont = UIFont.systemFont(ofSize: ceil(baseFillFont.pointSize / 2.8))
        let numberPadding: CGFloat = cellSideLength / 20
        
        // user cursor word indicator
        if self.userCursorWordIndicatorLayer.superlayer == nil {
            self.puzzleContainerView.layer.addSublayer(self.userCursorWordIndicatorLayer)
            self.userCursorWordIndicatorLayer.backgroundColor = UIColor.systemPink.withAlphaComponent(0.1).cgColor
            let transition = CATransition()
            transition.duration = 0.05
            self.userCursorWordIndicatorLayer.actions = [
                "bounds": transition,
                "position": transition,
                "size": transition
            ]
        }
        
        let wordExtent = self.findCurrentWordExtent()
        let oldWordIndicatorFrame = self.userCursorWordIndicatorLayer.frame
        switch self.userCursor.direction {
            case .across:
                self.userCursorWordIndicatorLayer.frame = CGRect(
                    x: cellSideLength * CGFloat(wordExtent.location),
                    y: cellSideLength * CGFloat(self.userCursor.coordinates.row),
                    width: cellSideLength * CGFloat(wordExtent.length),
                    height: cellSideLength)
            case .down:
                self.userCursorWordIndicatorLayer.frame = CGRect(
                    x: cellSideLength * CGFloat(self.userCursor.coordinates.cell),
                    y: cellSideLength * CGFloat(wordExtent.location),
                    width: cellSideLength,
                    height: cellSideLength * CGFloat(wordExtent.length))
        }
        
        let separatorCount = self.puzzleGrid.count * self.puzzleGrid[0].count - 2
        self.updateTextLayerCount(target: cellCount, font: baseFillFont)
        self.updateSeparatorCount(target: separatorCount)
        
        var textLayerIndex = 0
        var cellNumber = 1
        
        var acrossSequence: [SequenceEntry] = []
        var downSequence: [SequenceEntry] = []
        
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
                    numberTextLayer.foregroundColor = UIColor.label.cgColor
                    numberTextLayer.string = "\(cellNumber)"
                    numberTextLayer.frame = CGRect(x: CGFloat(itemIndex) * cellSideLength + numberPadding,
                                                   y: CGFloat(rowIndex) * cellSideLength + numberPadding,
                                                   width: cellSideLength,
                                                   height: numberFont.lineHeight)
                    
                    if self.isFirstLayout && cellNumber == 1 {
                        self.userCursor.coordinates = CellCoordinates(row: rowIndex, cell: itemIndex)
                    }
                    
                    if  // at the beginning or the previous one is a word boundary
                        (rowIndex == 0 || (self.puzzleGrid[rowIndex - 1][itemIndex] == ".")) &&
                        // not at the end
                        (rowIndex < self.puzzleGrid.count - 1 &&
                        // next one isn't a word boundary
                        self.puzzleGrid[rowIndex + 1][itemIndex] != ".") {
                        downSequence.append((cellNumber, CellCoordinates(row: rowIndex, cell: itemIndex)))
                    }
                    
                    if  // previous one is a word boundary or the beginning of the row
                        (itemIndex == 0 || self.puzzleGrid[rowIndex][itemIndex - 1] == ".") &&
                        // current one isn't a word boundary
                        self.puzzleGrid[rowIndex][itemIndex] != "." {
                        acrossSequence.append((cellNumber, CellCoordinates(row: rowIndex, cell: itemIndex)))
                    }
                    
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
                        
                        if let solutionEntry = self.solution[rowIndex][itemIndex] {
                            layer.string = solutionEntry.value
                            if let correctness = solutionEntry.correctness {
                                switch correctness {
                                    case .correct:
                                        layer.foregroundColor = UIColor.systemBlue.cgColor
                                    case .incorrect:
                                        layer.foregroundColor = UIColor.systemRed.cgColor
                                }
                            } else {
                                layer.foregroundColor = UIColor.label.cgColor
                            }
                        } else {
                            layer.string = nil
                        }
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
        
        self.acrossSequence = acrossSequence
        self.downSequence = downSequence
        
        // separators
        for i in 0..<self.puzzleGrid.count - 1 {
            let horizontal = self.separatorLayers[i]
            let offset = CGFloat(i + 1) * cellSideLength
            horizontal.frame = CGRect(x: 0, y: offset, width: self.frame.size.width, height: 0.5)
        }
        for i in (self.puzzleGrid.count)..<self.puzzleGrid.count + self.puzzleGrid[0].count - 1 {
            let vertical = self.separatorLayers[i]
            let offset = CGFloat(i - self.puzzleGrid.count + 1) * cellSideLength
            let newHeight = self.puzzleContainerView.frame.size.height * (1 / self.scrollView.zoomScale)
            vertical.frame = CGRect(x: offset, y: 0, width: 0.5, height: newHeight)
        }
        
        // cursors
        self.syncCursorLayerCount()
        for (userId, cursor) in self.cursors {
            guard let layer = self.cursorIndicatorLayers[userId] else { return }

            layer.backgroundColor = cursor.player.color.withAlphaComponent(Constant.otherPlayerCursorOpacity).cgColor
            layer.frame = CGRect(x: CGFloat(cursor.coordinates.cell) * cellSideLength,
                                 y: CGFloat(cursor.coordinates.row) * cellSideLength,
                                 width: cellSideLength,
                                 height: cellSideLength)
        }
        
        // user cursor letter indicator
        if self.userCursorLetterIndicatorLayer.superlayer == nil {
            self.puzzleContainerView.layer.addSublayer(self.userCursorLetterIndicatorLayer)
            self.userCursorLetterIndicatorLayer.borderColor = UIColor.systemPink.cgColor
            self.userCursorLetterIndicatorLayer.borderWidth = 2
        }
        self.userCursorLetterIndicatorLayer.frame = CGRect(x: CGFloat(self.userCursor.coordinates.cell) * cellSideLength,
                                                     y: CGFloat(self.userCursor.coordinates.row) * cellSideLength,
                                                     width: cellSideLength,
                                                     height: cellSideLength)
        
        if oldWordIndicatorFrame != self.userCursorWordIndicatorLayer.frame, let modelLocation = self.findCurrentClueCellNumber() {
            self.delegate?.puzzleView(self, 
                                      userCursorDidMoveToClueIndex: modelLocation.clueIndex,
                                      sequenceIndex: modelLocation.sequenceIndex, 
                                      direction: modelLocation.direction)
        }
        
        self.isFirstLayout = false
        self.invalidateIntrinsicContentSize()
    }
    
    func itemRequiresNumberLabel(_ item: String?, atRow row: Int, index: Int) -> Bool {
        return (row == 0 || index == 0) && item != "." ||
               (row > 0 && self.puzzleGrid[row - 1][index] == ".") && item != "." ||
               (index > 0 && self.puzzleGrid[row][index - 1] == ".") && item != "."
    }
    
    func createNumberTextLayer() -> CATextLayer {
        let layer = CATextLayer()
        layer.foregroundColor = UIColor.label.cgColor
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
                let layer = CALayer()
                self.cursorIndicatorLayers[userId] = layer
                self.puzzleContainerView.layer.insertSublayer(layer, at: 0)
            }
        }
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
                    "contents": NSNull(),
                    "foregroundColor": NSNull()
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
    
    func advanceUserCursorToNextLetter() {
        let current = self.userCursor.coordinates
        func nextCandidate(after lastCandidate: CellCoordinates) -> CellCoordinates {
            switch self.userCursor.direction {
                case .across:
                    if lastCandidate.cell + 1 >= self.puzzleGrid[0].count {
                        return current
                    } else {
                        return CellCoordinates(row: lastCandidate.row, cell: lastCandidate.cell + 1)
                    }
                case .down:
                    if lastCandidate.row + 1 >= self.puzzleGrid.count {
                        return current
                    } else {
                        return CellCoordinates(row: lastCandidate.row + 1, cell: lastCandidate.cell)
                    }
            }
        }
        
        var candidate = nextCandidate(after: current)
        if candidate == current {
            return
        }
        
        while self.puzzleGrid[candidate.row][candidate.cell] == "." || self.solution[candidate.row][candidate.cell]?.correctness == .correct  {
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
                        lastCandidate.cell == self.solution[lastCandidate.row].count - 1 && self.solution[lastCandidate.row][lastCandidate.cell] != nil {
                        return current
                    } else {
                        return CellCoordinates(row: lastCandidate.row, cell: lastCandidate.cell - 1)
                    }
                case .down:
                    if lastCandidate.row - 1 < 0 ||
                        lastCandidate.row == self.solution.count - 1 && self.solution[lastCandidate.row][lastCandidate.cell]?.value != nil {
                        return current
                    } else {
                        return CellCoordinates(row: lastCandidate.row - 1, cell: lastCandidate.cell)
                    }
            }
        }
        
        
        var candidate = nextCandidate(after: current)
        
        while self.puzzleGrid[candidate.row][candidate.cell] == "." || self.solution[candidate.row][candidate.cell]?.correctness == .correct {
            candidate = nextCandidate(after: candidate)
            if candidate == current {
                return
            }
        }
        
        self.userCursor = UserCursor(coordinates: candidate, direction: self.userCursor.direction)
    }
    
    func advanceUserCursorToNextWord() {
        let wordExtent = self.findCurrentWordExtent()
        var rollover = false
        switch self.userCursor.direction {
            case .across:
                let firstLetterCoordinates = CellCoordinates(row: self.userCursor.coordinates.row, cell: wordExtent.location)
                guard let currentIndex = self.acrossSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) else { return }
                let newIndex = (currentIndex + 1) % self.acrossSequence.count
                let newCoordinates = self.acrossSequence[newIndex]
                rollover = (newIndex == 0)
                self.userCursor.coordinates = newCoordinates.coordinates
            case .down:
                let firstLetterCoordinates = CellCoordinates(row: wordExtent.location, cell: self.userCursor.coordinates.cell)
                guard let currentIndex = self.downSequence.firstIndex(where: { $0.coordinates == firstLetterCoordinates }) else { return }
                let newIndex = (currentIndex + 1) % self.downSequence.count
                let newCoordinates = self.downSequence[newIndex]
                rollover = (newIndex == 0)
                self.userCursor.coordinates = newCoordinates.coordinates
        }
        
        if rollover {
            self.toggleDirection()
        }
        
        if solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell]?.correctness == .correct {
            self.advanceUserCursorToNextLetter()
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
        
        if trailingEdge {
            let newWordExtent = self.findCurrentWordCellCoordinates()
            if let lastNonCorrectCell = newWordExtent.reversed().first(where: { self.solution[$0.row][$0.cell]?.correctness != .correct }) {
                self.userCursor.coordinates = lastNonCorrectCell
            }
        } else if solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell]?.correctness == .correct {
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
                    self.puzzleGrid[coordinates.row][coordinates.cell + 1] == "." ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1.row][$1.cell]?.correctness == .correct })
                    
            case .down:
                // cells in the word after the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.row > coordinates.row })
                
                return
                    // at end of column
                    coordinates.row == self.puzzleGrid.count - 1 ||
                    // at the end of the word
                    self.puzzleGrid[coordinates.row + 1][coordinates.cell] == "." ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1.row][$1.cell]?.correctness == .correct })
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
                    coordinates.cell == 0 ||
                    // at the beginning of the word
                    self.puzzleGrid[coordinates.row][coordinates.cell - 1] == "." ||
                    // cells of the word before this one are checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1.row][$1.cell]?.correctness == .correct })
                    
            case .down:
                // cells in the word after the current cell
                let wordExtent = self.findCurrentWordCellCoordinates().filter({ $0.row < coordinates.row })
                
                return
                    // at beginning of column
                    coordinates.row == 0 ||
                    // at the beginning of the word
                    self.puzzleGrid[coordinates.row - 1][coordinates.cell] == "." ||
                    // remainder of the word is checked and correct
                    wordExtent.reduce(into: true, { $0 = $0 && self.solution[$1.row][$1.cell]?.correctness == .correct })
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
    
    func findCurrentWordExtent() -> NSRange {
        var firstLetterIndex = self.userCursor.direction == .across ? self.userCursor.coordinates.cell : self.userCursor.coordinates.row
        var lastLetterIndex = firstLetterIndex
        var firstLetterFound = false
        var lastLetterFound = false
        
        while !(firstLetterFound && lastLetterFound) {
            if !firstLetterFound {
                if firstLetterIndex - 1 < 0 {
                    firstLetterFound = true
                } else {
                    switch self.userCursor.direction {
                        case .across:
                            let candidateCell = self.puzzleGrid[self.userCursor.coordinates.row][firstLetterIndex - 1]
                            if candidateCell == "." {
                                firstLetterFound = true
                            } else {
                                firstLetterIndex -= 1
                            }
                        case .down:
                            let candidateCell = self.puzzleGrid[firstLetterIndex - 1][self.userCursor.coordinates.cell]
                            if candidateCell == "." {
                                firstLetterFound = true
                            } else {
                                firstLetterIndex -= 1
                            }
                    }
                }
            }
            
            if !lastLetterFound {
                if self.userCursor.direction == .across && lastLetterIndex + 1 > self.puzzleGrid[0].count - 1 {
                    lastLetterFound = true
                } else if self.userCursor.direction == .down && lastLetterIndex + 1 > self.puzzleGrid.count - 1 {
                    lastLetterFound = true
                } else {
                    switch self.userCursor.direction {
                        case .across:
                            let candidateCell = self.puzzleGrid[self.userCursor.coordinates.row][lastLetterIndex + 1]
                            if candidateCell == "." {
                                lastLetterFound = true
                            } else {
                                lastLetterIndex += 1
                            }
                        case .down:
                            let candidateCell = self.puzzleGrid[lastLetterIndex + 1][self.userCursor.coordinates.cell]
                            if candidateCell == "." {
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
        let sideLength = self.cellSideLength * self.scrollView.zoomScale
        let pointCoords = tap.location(in: self.scrollView)
        
        guard self.puzzleContainerView.frame.contains(pointCoords) else {
            print("tapped outside puzzle")
            return
        }
        
        let cellCoords = CellCoordinates(row: Int(pointCoords.y / sideLength),
                                         cell: Int(pointCoords.x / sideLength))
        
        let item = self.puzzleGrid[cellCoords.row][cellCoords.cell]

        if item == nil || item == "." {
            return
        } else if cellCoords == self.userCursor.coordinates {
            self.userCursor = UserCursor(coordinates: cellCoords, direction: self.userCursor.direction.opposite)
        } else {
            self.userCursor = UserCursor(coordinates: cellCoords, direction: self.userCursor.direction)
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

extension PuzzleView: UIKeyInput {
    
    var hasText: Bool {
        true
    }
    
    func insertText(_ text: String) {
        
        func advance() {
            if self.isUserCursorAtTrailingWordBoundary() {
                self.advanceUserCursorToNextWord()
            } else {
                self.advanceUserCursorToNextLetter()
            }
        }
        
        if text == " " {
            self.toggleDirection()
            return
        } else if text == "\n" || self.solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell]?.correctness == .correct {
            advance()
        } else {
            self.delegate?.puzzleView(self, didEnterText: text.uppercased(), atCoordinates: self.userCursor.coordinates)
            advance()
        }
    }
    
    func deleteBackward() {
        if let currentCellEntry = self.solution[self.userCursor.coordinates.row][self.userCursor.coordinates.cell],
            currentCellEntry.correctness != .correct {
            
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
