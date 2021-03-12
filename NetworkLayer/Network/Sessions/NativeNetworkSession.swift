//
//  NativeNetworkSession.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

/// A custom session to wrapper third-party framework
public final class NativeNetworkSession: NetworkSession {

    private let urlSession = URLSession(
        configuration: URLSessionConfiguration.default,
        delegate: nil,
        delegateQueue: nil
    )
    
    public init() {}

    public func request(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkCancelable {
        let task = urlSession.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}

extension URLSessionDataTask: NetworkCancelable {
    
    public func cancelRequest() {
        cancel()
    }
}
