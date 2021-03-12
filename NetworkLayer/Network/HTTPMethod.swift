//
//  HTTPMethod.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

/// HTTP methods specified in a `Request` object.
///
/// - get: The GET method.
/// - post: The POST method.
/// - put: The PUT method.
/// - delete: The DELETE method.
public enum HTTPMethod: String {
    
    /// The GET method.
    case get = "GET"
    
    /// The POST method.
    case post = "POST"
    
    /// The PUT method.
    case put = "PUT"
    
    /// The DELETE method.
    case delete = "DELETE"
}
