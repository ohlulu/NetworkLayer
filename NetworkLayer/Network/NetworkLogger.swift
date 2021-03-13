//
//  NetworkLogger.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/13.
//

import Foundation

public protocol NetworkLogger {
    var needLog: Bool { get }
    func log(_ message: String)
}

public final class PrintLogger: NetworkLogger {

    #if DEBUG
        public let needLog: Bool = true
    #else
        public let needLog: Bool = false
    #endif

    public func log(_ message: String) {
        print(message)
    }
}
