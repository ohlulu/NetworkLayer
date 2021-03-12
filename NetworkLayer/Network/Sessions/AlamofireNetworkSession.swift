//
//  AlamofireNetworkSession.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation

#if canImport(Alamofire)
import Alamofire

/// A custom session to wrapper third-party framework
public final class AlamofireNetworkSession: NetworkSession {

    // provide a default session
    public static let `default` = DefaultNetworkSession()

    // wrapper alamofire session
    private let afSession: Alamofire.Session

    // Initializer
    private init() {

        // custom alamofire session here.
        self.afSession = Alamofire.Session()
    }

    // confirm `NetworkSession` protocol
    public func request(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancelable {
        let task = afSession.request(request)
            .responseData { dataResponse in
                completion(dataResponse.data, dataResponse.response, dataResponse.error)
            }
        return task
    }
}
#endif
