//
//  ParameterEncoder.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

/// Encode `Parameters: [String: Any]` to a request.
public protocol ParameterEncoder {
    func encode(urlRequest: URLRequest, withParameters parameters: [String: Any]) throws -> URLRequest
}

public struct HTTPBodyEncoder: ParameterEncoder {
    
    public func encode(urlRequest: URLRequest, withParameters parameters: [String: Any]) throws -> URLRequest {
        let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
        var request = urlRequest
        request.httpBody = data
        return request
    }
}
