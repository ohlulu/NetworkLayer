//
//  NetworkResponse.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/13.
//

import Foundation

/// Contains `Data`, `URLRequest`, `HTTPURLResponse`
/// Mainly used in `NetworkPlugin` -> `func didReceive(_ response: NetworkResponse)`
public struct NetworkResponse {

    /// The response data.
    public let data: Data
    /// The original URLRequest for the response.
    public let request: URLRequest?
    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    public init(data: Data, request: URLRequest? = nil, response: HTTPURLResponse? = nil) {
        self.data = data
        self.request = request
        self.response = response
    }
}
