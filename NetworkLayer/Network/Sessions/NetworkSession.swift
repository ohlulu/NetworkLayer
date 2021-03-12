//
//  NetworkSession.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation


/// Provide request-able, response-able method
public protocol NetworkSession {

    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

    func request(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancelable
}

