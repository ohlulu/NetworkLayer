//
//  NetworkLayerTests.swift
//  NetworkLayerTests
//
//  Created by Ohlulu on 2021/3/12.
//

@testable import NetworkLayer
import XCTest

class Adapter_Tests: XCTestCase {

    var mockRequest: URLRequest!

    override func setUp() {
        mockRequest = URLRequest(url: URL(string: "http://www.ohlulu.com")!)
    }

    // MARK: - HeaderAdapter

    func test_HeaderAdapter() throws {

        let fakeHeader = [
            "X-Device": "iphone"
        ]

        let adapter = HeaderAdapter(fields: fakeHeader)
        let newRequest = try adapter.adapted(mockRequest)
        XCTAssertEqual(newRequest.allHTTPHeaderFields?["X-Device"], "iphone")
    }

    // MARK: - MethodAdapter

    func test_MethodAdapter() throws {

        // GET
        let adapter1 = MethodAdapter(method: .get)
        let newRequest1 = try adapter1.adapted(mockRequest)
        XCTAssertEqual(newRequest1.httpMethod, "GET")
        
        // POST
        let adapter2 = MethodAdapter(method: .post)
        let newRequest2 = try adapter2.adapted(mockRequest)
        XCTAssertEqual(newRequest2.httpMethod, "POST")
        
        // PUT
        let adapter3 = MethodAdapter(method: .put)
        let newRequest3 = try adapter3.adapted(mockRequest)
        XCTAssertEqual(newRequest3.httpMethod, "PUT")
        
        // DELETE
        let adapter4 = MethodAdapter(method: .delete)
        let newRequest4 = try adapter4.adapted(mockRequest)
        XCTAssertEqual(newRequest4.httpMethod, "DELETE")
    }

    // MARK: - TaskAdapter
    
    func test_simpleTask_shouldNotModifyTheRequest() throws {
        let adapter = TaskAdapter(task: .simple)
        let newRequest = try adapter.adapted(mockRequest)
        XCTAssertEqual(newRequest, mockRequest)
    }

    struct URLParameterRequest: Encodable {
        let string: String = "ohlulu"
        let int: Int = 10
        let bool: Bool = true
    }
    
    func test_TaskAdapter_withURLEncode_queryItemShouldCorrect() throws {
        let adapter = TaskAdapter(task: .urlParameters(URLParameterRequest()))

        let newRequest = try adapter.adapted(mockRequest)
        let urlComponent = URLComponents(url: newRequest.url!, resolvingAgainstBaseURL: false)
        // url:         www.pinkoi.com?int=10&string=ohlulu&bool=1&array=a1,a2
        // encoded url: www.pinkoi.com?int=10&string=ohlulu&bool=1&array=a1%2Ca2
        let queryItem = try XCTUnwrap(urlComponent?.percentEncodedQueryItems)
        XCTAssertEqual(queryItem.getValue(withName: "string"), "ohlulu")
        XCTAssertEqual(queryItem.getValue(withName: "int"), "10")
        XCTAssertEqual(queryItem.getValue(withName: "bool"), "1")
    }

    struct NeedEscapeParameter: Encodable {
        let string1: String = "喔嚕嚕"
        let string2: String = "oh lulu."
        let array = ["a1", "a2"]
    }

    func test_TaskAdapter_withURLEncode_queryItemShouldBeEscaped() throws {
        let adapter = TaskAdapter(task: .urlParameters(NeedEscapeParameter()))
        let newRequest = try adapter.adapted(mockRequest)
        let urlComponent = URLComponents(url: newRequest.url!, resolvingAgainstBaseURL: false)

        // https://www.urlencoder.org/
        let queryItem = try XCTUnwrap(urlComponent?.percentEncodedQueryItems)
        XCTAssertEqual(queryItem.getValue(withName: "string1"), "%E5%96%94%E5%9A%95%E5%9A%95")
        XCTAssertEqual(queryItem.getValue(withName: "string2"), "oh%20lulu.")
        XCTAssertEqual(queryItem.getValue(withName: "array"), "a1%2Ca2")
    }

    func test_TaskAdapter_withJSONEncodeEncodable_shouldCorrectEncodeToHTTPBody() throws {
        let adapter = TaskAdapter(task: .jsonEncodable(NeedEscapeParameter()))
        let request = try adapter.adapted(mockRequest)
        let httpBody = try XCTUnwrap(request.httpBody)
        let data = try JSONEncoder().encode(NeedEscapeParameter())
        XCTAssertEqual(data, httpBody)
    }

    func test_TaskAdapter_withJSONEncodeDictionary_shouldCorrectEncodeToHTTPBody() throws {
        let dictionary1 = [
            "string1": "喔嚕嚕",
            "string2": "oh lulu."
        ]
        let adapter = TaskAdapter(task: .bodyWithParameters(dictionary1, encoder: HTTPBodyEncoder()))
        let request = try adapter.adapted(mockRequest)
        let httpBody = try XCTUnwrap(request.httpBody)
        let jsonObject = try JSONSerialization.jsonObject(with: httpBody, options: [])
        let dictionary2 = try XCTUnwrap(jsonObject as? [String: String])
        XCTAssertEqual(dictionary1, dictionary2)
    }
}

private extension Array where Element == URLQueryItem {
    func getValue(withName name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}
