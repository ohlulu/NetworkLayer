//
//  NetworkAdapter.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

/// Adapts a `URLRequest`
public protocol NetworkAdapter {

    /// Adapts an input `URLRequest` and return a modified object.
    ///
    /// - Parameter request: The request to be adapted.
    /// - Returns: The modified `URLRequest` object.
    /// - Throws: An error during the adapting process.
    func adapted(_ request: URLRequest) throws -> URLRequest
}

// MARK: - HeaderAdapter

/// Adapts header fields to a request.
struct HeaderAdapter: NetworkAdapter {

    private let fields: [String: String]

    init(fields: [String: String]) {
        self.fields = fields
    }

    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        fields.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

// MARK: - MethodAdapter

/// Adapts HTTP method to a request.
struct MethodAdapter: NetworkAdapter {

    let method: HTTPMethod

    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.httpMethod = method.rawValue
        return request
    }
}

// MARK: - TaskAdapter

/// Implementation `URLRequest` according to the `NetworkTask`.
struct TaskAdapter: NetworkAdapter {
    
    private struct AnyEncodableWrapper: Encodable {

        private let encodable: Encodable

        init(_ encodable: Encodable) {
            self.encodable = encodable
        }

        func encode(to encoder: Encoder) throws {
            try encodable.encode(to: encoder)
        }
    }
    
    private let task: NetworkTask
    
    // Life cycle
    init(task: NetworkTask) {
        self.task = task
    }
    
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        switch task {
        case .simple:
            return request
        case let .urlEncode(encodable: encodable):
            let encodableObject = AnyEncodableWrapper(encodable)
            return try Result<URLRequest, Error> { try URLEncoder().encode(encodableObject, with: request) }
                .mapError { NetworkError.buildRequestFailed(reason: .urlEncodeFail(error: $0)) }.get()

        case let .jsonEncode(encodable: encodable):
            let encodableObject = AnyEncodableWrapper(encodable)
            request.httpBody = try Result<Data, Error> { try JSONEncoder().encode(encodableObject) }
                .mapError { NetworkError.buildRequestFailed(reason: .jsonEncodeFail(error: $0)) }.get()
            return request
            
        case let .jsonEncode(dictionary: dictionary, encoder: encoder):
            return try Result<URLRequest, Error> { try encoder.encode(urlRequest: request, withParameters: dictionary) }
                .mapError { NetworkError.buildRequestFailed(reason: .jsonEncodeFail(error: $0)) }.get()
        }
    }
}
