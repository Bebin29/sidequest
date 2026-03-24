//
//  APIResponse.swift
//  Sidequest
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    let data: T
}

struct APIListResponse<T: Codable>: Codable {
    let data: [T]
    let count: Int
}

struct APIErrorResponse: Codable {
    let error: String
}

struct APIMessageResponse: Codable {
    let message: String
}
