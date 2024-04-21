//
//  TimeClock.swift
//  DownForACross
//
//  Created by Justin Hill on 4/19/24.
//

import Foundation

protocol TimeClockDelegate: AnyObject {
    func timeClock(_ timeClock: TimeClock, stateDidChange: TimeClock.ClockState)
}

class TimeClock {

    typealias Instant = (state: ClockState, elapsedTime: TimeInterval)
    typealias FormattedInstant = (state: ClockState, elapsedTime: String)

    let zeroPaddingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        return formatter
    }()

    enum ClockState {
        case stopped
        case started
    }

    let autoPauseInterval: TimeInterval = 60

    private var lastEventTimestamp: TimeInterval = 0
    private var recordedElapsedTime: TimeInterval = 0

    weak var delegate: TimeClockDelegate?
    private var autoPauseTimer: Timer?

    var currentInstant: Instant {
        let now = Date().timeIntervalSince1970
        let timeSinceLastEvent = (now - self.lastEventTimestamp)
        let totalElapsedTime = self.recordedElapsedTime + min(self.autoPauseInterval, timeSinceLastEvent)

        return (timeSinceLastEvent >= self.autoPauseInterval ? .stopped : .started , totalElapsedTime)
    }

    var formattedCurrentInstant: FormattedInstant {
        let instant = self.currentInstant
        let elapsedInt = Int(instant.elapsedTime)
        let hours = elapsedInt / 3600
        let minutes = (elapsedInt % 3600) / 60
        let seconds = elapsedInt % 60

        var timeString = hours > 0 ? "\(hours):" : ""
        timeString.append("\(self.zeroPaddingFormatter.string(from: NSNumber(value: minutes))!):\(self.zeroPaddingFormatter.string(from: NSNumber(value: seconds))!)")

        if instant.state == .stopped {
            timeString = "(\(timeString))"
        }

        return (instant.state, timeString)
    }

    func accountFor(rawEvent: [String: Any]) {
        guard let type = rawEvent["type"] as? String, let timestamp = rawEvent["timestamp"] as? TimeInterval else { return }
        let secondsTimestamp = timestamp / 1000

        let currentState = self.currentInstant.state

        if type != "create" {
            self.recordedElapsedTime += min(secondsTimestamp - self.lastEventTimestamp, self.autoPauseInterval)
        }

        self.lastEventTimestamp = secondsTimestamp

        self.autoPauseTimer?.invalidate()
        self.autoPauseTimer = Timer.scheduledTimer(withTimeInterval: self.autoPauseInterval, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            self.delegate?.timeClock(self, stateDidChange: .stopped)
        })

        if currentState == .stopped {
            self.delegate?.timeClock(self, stateDidChange: .started)
        }

        print(self.formattedCurrentInstant.elapsedTime)
    }

}
