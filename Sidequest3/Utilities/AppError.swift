//
//  AppError.swift
//  Sidequest
//

import Foundation

enum AppError: LocalizedError {
    case network(underlying: Error)
    case decoding(underlying: Error)
    case server(statusCode: Int, message: String?)
    case notFound
    case unauthorized
    case unknown(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .decoding(let error):
            return "Datenverarbeitungsfehler: \(error.localizedDescription)"
        case .server(let code, let message):
            return "Serverfehler (\(code)): \(message ?? "Unbekannt")"
        case .notFound:
            return "Ressource nicht gefunden."
        case .unauthorized:
            return "Nicht autorisiert."
        case .unknown(let error):
            return "Unbekannter Fehler: \(error?.localizedDescription ?? "–")"
        }
    }
}
