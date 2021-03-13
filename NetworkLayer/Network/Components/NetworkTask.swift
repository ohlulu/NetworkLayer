//
//  NetworkTask.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

/// Represents an HTTP task.
/// Design concept reference from Moya
///
/// - Note: After iOS13, `HTTP body` should not have any data, if `HTTP method` is "GET".
/// https://developer.apple.com/documentation/ios-ipados-release-notes/ios-13-release-notes#3319752.
public enum NetworkTask {
    
    /// A simple request, without any parameter.
    case simple
    
    /// A request URL set with `Encodable` object.
    case urlParameters(Encodable)

    /// A request body set with `Encodable` object.
    case jsonEncodable(Encodable)

    /// A requests body set with `parameters`, use `encoder`.
    case bodyWithParameters([String: Any], encoder: ParameterEncoder)
}
