//
//  Logger.swift
//  Sidequest
//

import os
import Foundation

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sidequest"

    static let general = os.Logger(subsystem: subsystem, category: "general")
    static let network = os.Logger(subsystem: subsystem, category: "network")
    // swiftlint:disable:next identifier_name
    static let ui = os.Logger(subsystem: subsystem, category: "ui")
    static let data = os.Logger(subsystem: subsystem, category: "data")
}
