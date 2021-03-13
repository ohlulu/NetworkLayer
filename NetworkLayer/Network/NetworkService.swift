//
//  NetworkService.swift
//  NetworkLayer
//
//  Created by Ohlulu on 2021/3/13.
//

import Foundation

/// Send a `NetworkRequest` object through a `NetworkSession` object
///     1. Build up` URLRequest` with a `NetworkRequest`
///     2. Callback to `NetworkRequest.[NetworkPlugin]` in request designated moment.
///     3. handle the response in the `NetworkRequest.[NetworkDecision]` designed way
public class NetworkService {

    static let `default` = NetworkService()

    private let session: NetworkSession

    /// You can inject `session`.
    /// ⚠️ Note. capture service until receive response.
    public init(
        session: NetworkSession = NativeNetworkSession()
    ) {
        self.session = session
    }
}

// MARK: - Send request methods

public extension NetworkService {

    typealias CompletionHandler<R: NetworkRequest> = (Swift.Result<R.Entity, NetworkError>) -> Void

    @discardableResult
    func send<R: NetworkRequest>(
        _ request: R,
        completion: @escaping CompletionHandler<R>
    ) -> NetworkCancelable? {
        send(request, decision: nil, completion: completion)
    }

    @discardableResult
    internal func send<R: NetworkRequest>(
        _ request: R,
        decision: [NetworkDecision]?,
        completion: @escaping CompletionHandler<R>
    ) -> NetworkCancelable? {

        // Build up request.
        let urlRequest: URLRequest
        do {
            urlRequest = try build(request: request)
        } catch {
            completion(.failure(error.asNetworkError()))
            return nil
        }

        let plugins = request.plugins // 因為 plugins 是 compute property，需要 capture 一份，不然下面的 didReceive 又會是一份新的 plugins
        // plugin callback moment 1
        plugins.forEach { $0.willSend(request) }

        // Create and resume task
        let task = session.request(urlRequest) { [weak self] _data, _response, _error in

            guard let self = self else { return }

            let data: Data
            let urlResponse: HTTPURLResponse

            let sanitizedResponse = self.sanitizedRawResponse(data: _data, urlResponse: _response, error: _error)
            switch sanitizedResponse {
            case .success((let _data, let _response)):
                data = _data
                urlResponse = _response
            case let .failure(error):
                completion(.failure(error))
                return
            }

            let decision = decision ?? request.decisions
            self.handle(request: request, data: data, response: urlResponse, decisions: decision) { result in

                let response = NetworkResponse(data: data, request: urlRequest, response: urlResponse)
                // plugin callback moment 2
                plugins.forEach { $0.didReceive(response) }

                switch result {
                case .success(let entity):
                    completion(.success(entity))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        return task
    }
}

// MARK: - Handle response with decisions

private extension NetworkService {

    func handle<Request: NetworkRequest>(
        request: Request,
        data: Data,
        response: HTTPURLResponse,
        decisions: [NetworkDecision],
        completionHandler: @escaping CompletionHandler<Request>
    ) {

        guard !decisions.isEmpty else {
            fatalError("decision is already empty, but completion handler not be done.")
        }

        var decisions = decisions
        let currentDecision = decisions.removeFirst()

        if !currentDecision.shouldApply(request: request, data: data, response: response) {
            handle(request: request, data: data, response: response, decisions: decisions, completionHandler: completionHandler)
            return
        }

        currentDecision.apply(request: request, data: data, response: response) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .next(let data, let response):
                self.handle(request: request, data: data, response: response, decisions: decisions, completionHandler: completionHandler)
            case .restart(let decisions):
                self.send(request, decision: decisions, completion: completionHandler)
            case .stop(let error):
                completionHandler(.failure(error))
            case .done(let entity):
                completionHandler(.success(entity))
            }
        }
    }
}

// MARK: - Helper method

extension NetworkService {

    func build<T: NetworkRequest>(request httpRequest: T) throws -> URLRequest {

        let fullURL = httpRequest.baseURL.appendingPathComponent(httpRequest.path)
        var request = URLRequest(url: fullURL)

        request = try httpRequest.adapters.reduce(request) { request, adapter in
            try adapter.adapted(request)
        }

        return request
    }

    /// Sanitized `Data?` `URLResponse?` `Error?` to `(Data, HTTPURLResponse)`
    func sanitizedRawResponse(
        data: Data?, urlResponse: URLResponse?, error: Error?
    ) -> Result<(Data, HTTPURLResponse), NetworkError> {

        if let error = error {
            let error = NetworkError.responseFailed(reason: .URLSessionError(error))
            return .failure(error)
        }

        guard let response = urlResponse as? HTTPURLResponse else {
            let error = NetworkError.responseFailed(reason: .nonHTTPURLResponse)
            return .failure(error)
        }

        guard let data = data else {
            let error = NetworkError.responseFailed(reason: .nilData)
            return .failure(error)
        }

        return .success((data, response))
    }
}
