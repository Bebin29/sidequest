//
//  Constants.swift
//  Sidequest
//

import Foundation

enum Constants {
    enum API {
        static let baseURL = "http://217.154.243.150"
        static let timeoutInterval: TimeInterval = 30
    }

    enum App {
        static let name = "Sidequest"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
