//
//  NetworkRequest.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/13.
//

import Foundation

/// API request components
public protocol NetworkRequest {

    associatedtype Entity: Decodable

    var baseURL: URL { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var headers: [String: String] { get }

    var task: NetworkTask { get }

    var adapters: [NetworkAdapter] { get }

    var decisions: [NetworkDecision] { get }

    var plugins: [NetworkPlugin] { get }
}

// Provided NetworkRequest default value
public extension NetworkRequest {

    var baseURL: URL {
        return URL(string: "https://")! // return your base url hear
    }

    var adapters: [NetworkAdapter] {
        return [
            HeaderAdapter(fields: headers),
            MethodAdapter(method: method),
            TaskAdapter(task: task)
        ]
    }

    var decisions: [NetworkDecision] {
        return [
            StatusCodeDecision(valid: 200 ..< 399),
            CookieDecision(),
            RetryDecision(retryCount: 2),
            DetectAPIErrorDecision(),
            DecodeDecision()
        ]
    }

    var plugins: [NetworkPlugin] {
        return [
            LogPlugin(logger: PrintLogger()),
        ]
    }

    var headers: [String: String] {
        return [:]
    }
}
