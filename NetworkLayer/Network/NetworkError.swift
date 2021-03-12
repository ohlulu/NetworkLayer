//
//  NetworkError.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/12.
//

import Foundation
/**
  Define the project error what you own in HTTP response body.
 
 /// Error in the response body.
 public struct APIError: Decodable, Equatable {

     /// Similar to http status code
     enum Code: Int, Decodable {

         /// 400: :nodoc:
         case badRequest = 400

         /// 403: Need login.
         case forbidden = 403

         /// 409: :nodoc:
         case requestConflict = 409

         /// 426: :nodoc:
         case upgradeRequired = 426

         /// 503: Server down time.
         case serviceUnavailable = 503

         /// Receive a undefined error
         case undefined = 9999
     }

     /// See `APIError.Code`.
     let code: Code

     /// Error message.
     let message: String

     private enum CodingKeys: String, CodingKey {
         case code
         case message
     }

     /// Access control: internal for test
     internal init(code: APIError.Code, message: String) {
         self.code = code
         self.message = message
     }

     public init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         self.code = (try? container.decode(Code.self, forKey: .code)) ?? .undefined
         self.message = try container.decode(String.self, forKey: .message)
     }
 }
 
  */

// MARK: - Network Error.

/// Error in the entire network request.
public enum NetworkError: Error {

    public enum ResponseErrorReason {

        /// Receive invalid HTTP status code and data.
        case invalidHTTPStatus(code: Int, data: Data)

        /// The receive data cannot decode to an instance of the target type.
        case decodeFailed(Error)

        /// The response of `HTTPURLResponse` is nil.
        case nonHTTPURLResponse

        /// The response of `HTTPBody` is nil.
        case nilData

        /// The error from `URLSession`.
        case URLSessionError(Error)
    }

    /// About parameter error.
    public enum BuildRequestFailedReason: Swift.Error {

        /// URL encode failed with an error from `URLEncoder`
        case urlEncodeFail(error: Error)

        /// JSON encode failed with an error form `JSONEncoder` or `HTTPBodyEncoder`.
        case jsonEncodeFail(error: Error)

        /// invalid url
        case invalidURL
    }

    /// Occurred on `Service` build `URLRequest`,
    case buildRequestFailed(reason: BuildRequestFailedReason)

    /// An error with receive response
    case responseFailed(reason: ResponseErrorReason)

    /**
     If you define `APIError` then open it.
     /// An `APIError` with json response
     case apiError(error: APIError)
    */
    
    /// An error not be correct defined.
    case undefined(error: Error)

    public enum SpecificFailedReason: Swift.Error {
        /// empty url component QueryItems
        case emptyQueryItems
    }

    /// 特定的某些錯誤
    case specificFailed(reason: SpecificFailedReason)
}

// MARK: - Network convert helper.

public extension Error {

    func asNetworkError() -> NetworkError {
        return self as? NetworkError ?? .undefined(error: self)
    }
}

// MARK: - Network equal helper.

public extension NetworkError {

    var isNilData: Bool {
        if case .responseFailed(.nilData) = self {
            return true
        }
        return false
    }

    var isNonHTTPURLResponse: Bool {
        if case .responseFailed(.nonHTTPURLResponse) = self {
            return true
        }
        return false
    }

    var isURLSessionError: Bool {
        if case .responseFailed(.URLSessionError) = self {
            return true
        }
        return false
    }

    var isBuildRequestMethodNonsupport: Bool {
        if case .buildRequestFailed(.methodNonsupport) = self {
            return true
        }
        return false
    }
}
