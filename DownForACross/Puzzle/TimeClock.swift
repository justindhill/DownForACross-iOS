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
        case paused
        case started

    }

    let autoPauseInterval: TimeInterval = 60

    private var lastEventTimestamp: TimeInterval = 0
    private var recordedElapsedTime: TimeInterval = 0

    weak var delegate: TimeClockDelegate?
    private var autoPauseTimer: Timer?
    private var stopped: Bool = false
    private var createEventObserved: Bool = false

    var currentInstant: Instant {
        let now = Date().timeIntervalSince1970
        let timeSinceLastEvent = (now - self.lastEventTimestamp)
        let totalElapsedTime = self.recordedElapsedTime + min(self.autoPauseInterval, timeSinceLastEvent)

        if self.stopped {
            return (.stopped, self.recordedElapsedTime)
        } else {
            return (timeSinceLastEvent >= self.autoPauseInterval ? .paused : .started , totalElapsedTime)
        }
    }

    var formattedCurrentInstant: FormattedInstant {
        let instant = self.currentInstant
        let elapsedInt = Int(instant.elapsedTime)
        let hours = elapsedInt / 3600
        let minutes = (elapsedInt % 3600) / 60
        let seconds = elapsedInt % 60

        var timeString = hours > 0 ? "\(hours):" : ""
        timeString.append("\(self.zeroPaddingFormatter.string(from: NSNumber(value: minutes))!):\(self.zeroPaddingFormatter.string(from: NSNumber(value: seconds))!)")

        if instant.state == .paused {
            timeString = "(\(timeString))"
        }

        return (instant.state, timeString)
    }

    func accountForFakeEvent() {
        self.accountFor(rawEvent: [
            "type": "fake",
            "timestamp": Date().timeIntervalSince1970 * 1000
        ])
    }

    func accountFor(rawEvent: [String: Any]) {
        guard
            !self.stopped,
            let type = rawEvent["type"] as? String,
            let timestamp = rawEvent["timestamp"] as? TimeInterval else { return }

        print("CLOCK: accountFor")

        let secondsTimestamp = timestamp / 1000

        let currentState = self.currentInstant.state

        if type == "create" {
            self.lastEventTimestamp = secondsTimestamp
            self.createEventObserved = true
            return
        } else if !self.createEventObserved {
            return
        } else {
            self.recordedElapsedTime += min(secondsTimestamp - self.lastEventTimestamp, self.autoPauseInterval)
            print(recordedElapsedTime)
            self.lastEventTimestamp = secondsTimestamp
        }

        self.autoPauseTimer?.invalidate()
        self.autoPauseTimer = Timer.scheduledTimer(withTimeInterval: self.autoPauseInterval, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            self.recordedElapsedTime += min(secondsTimestamp - self.lastEventTimestamp, self.autoPauseInterval)
            self.delegate?.timeClock(self, stateDidChange: .paused)
        })

        if currentState == .paused {
            self.delegate?.timeClock(self, stateDidChange: .started)
        }

        withUnsafePointer(to: self) { ptr in
            print("\(ptr) \(self.stopped) " + self.formattedCurrentInstant.elapsedTime)
        }
    }

    func accountFor(rawEvents: [[String: Any]]) {
        rawEvents.forEach(self.accountFor(rawEvent:))
    }

    func start() {
        self.lastEventTimestamp = Date().timeIntervalSince1970
        self.stopped = false
    }

    func stop() {
        print("CLOCK: stopped")
        self.stopped = true
        self.autoPauseTimer?.invalidate()
        self.delegate?.timeClock(self, stateDidChange: .stopped)
    }

}
