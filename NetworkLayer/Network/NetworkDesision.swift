//
//  NetworkDesision.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/13.
//

import Foundation

/// The result of response `handle` method.
/// - next: continue next decision with the response's `Data` and `HTTPURLResponse`.
/// - restart: restart: Restart the whole request with the given decisions.
/// - stop: Stop handling process and report an error.
/// - done: A final result of all decisions and report a value
public enum NetworkDecisionAction<R: NetworkRequest> {
    case next(Data, HTTPURLResponse)
    case restart([NetworkDecision])
    case stop(NetworkError)
    case done(R.Entity)
}

public protocol NetworkDecision: AnyObject { // easier equatable

    func shouldApply<R: NetworkRequest>(request: R, data: Data, response: HTTPURLResponse) -> Bool

    func apply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse,
        action: @escaping (NetworkDecisionAction<R>) -> Void
    )
}

/// Valid status code
class StatusCodeDecision: NetworkDecision {

    let valid: Range<Int>

    init(valid: Range<Int>) {
        self.valid = valid
    }

    func shouldApply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse
    ) -> Bool {
        return !valid.contains(response.statusCode)
    }

    func apply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse,
        action: @escaping (NetworkDecisionAction<R>) -> Void
    ) {

        let reason = NetworkError.ResponseErrorReason.invalidHTTPStatus(code: response.statusCode, data: data)
        action(.stop(NetworkError.responseFailed(reason: reason)))
    }
}

/// Cookie Decision
class CookieDecision: NetworkDecision {
    func shouldApply<R>(request: R, data: Data, response: HTTPURLResponse) -> Bool where R: NetworkRequest {
        true
    }

    func apply<R>(request: R, data: Data, response: HTTPURLResponse, action: @escaping (NetworkDecisionAction<R>) -> Void) where R: NetworkRequest {
        CookieManager.saveCookieIfNeeded(from: response)
        action(.next(data, response))
    }
}

/// If failed, retry.
class RetryDecision: NetworkDecision {

    let retryCount: Int

    init(retryCount: Int) {
        self.retryCount = retryCount
    }

    func shouldApply<R>(request: R, data: Data, response: HTTPURLResponse) -> Bool where R: NetworkRequest {
        // TODO(API): 要確認一下原本的 retry logic
        let isStatusCodeValid = (200 ... 299).contains(response.statusCode)
        return !isStatusCodeValid && retryCount > 0
    }

    func apply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse,
        action: @escaping (NetworkDecisionAction<R>) -> Void
    ) {
        let newRetryDecision = RetryDecision(retryCount: retryCount - 1)
        let newDecisions = request.decisions.replacing(self, with: newRetryDecision)
        action(.restart(newDecisions))
    }
}

/// Detect `APIError` before `DecodeDecision`
class DetectAPIErrorDecision: NetworkDecision {

    let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func shouldApply<R: NetworkRequest>(request: R, data: Data, response: HTTPURLResponse) -> Bool {
        true
    }

    public func apply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse,
        action: @escaping (NetworkDecisionAction<R>) -> Void
    ) {
        if let wrapperErrorEntity = try? decoder.decode(APIErrorWrapper.self, from: data) {
            let errorEntity = wrapperErrorEntity.error
            action(.stop(NetworkError.apiError(error: errorEntity)))
        } else {
            action(.next(data, response))
        }
    }
}

/// Last decision, decode data to a `Request.Entity` object.
class DecodeDecision: NetworkDecision {

    let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func shouldApply<R: NetworkRequest>(request: R, data: Data, response: HTTPURLResponse) -> Bool {
        true
    }

    public func apply<R: NetworkRequest>(
        request: R,
        data: Data,
        response: HTTPURLResponse,
        action: @escaping (NetworkDecisionAction<R>) -> Void
    ) {

        do {
            let model = try decoder.decode(R.Entity.self, from: data)
            action(.done(model))
        } catch {
            let reason = NetworkError.ResponseErrorReason.decodeFailed(error)
            action(.stop(NetworkError.responseFailed(reason: reason)))
        }
    }
}

private extension Array where Element == NetworkDecision {

    func replacing(_ item: NetworkDecision, with newItem: NetworkDecision) -> [NetworkDecision] {
        var newDecisions = self
        guard let targetIndex = newDecisions.firstIndex(where: { $0 === item }) else { return self }
        newDecisions[targetIndex] = newItem
        return newDecisions
    }
}
