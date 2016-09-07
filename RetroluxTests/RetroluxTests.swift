//
//  RetroluxTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import XCTest
import Retrolux

/*
struct MockHTTPTask: HTTPTaskProtocol {
    let mockResponse: HTTPClientResponseData
    var callback: HTTPClientResponseData -> Void
    
    init(mockResponse: HTTPClientResponseData, callback: HTTPClientResponseData -> Void) {
        self.mockResponse = mockResponse
        self.callback = callback
    }
    
    func cancel() {}
    func resume() {}
}

class MockHTTPClient: HTTPClientProtocol {
    var mockResponse: HTTPClientResponseData?
    var args: (method: String, URL: NSURL, body: NSData?, headers: [String: String])?
    
    func makeAsynchronousRequest(method: String, URL: NSURL, body: NSData?, headers: [String : String], callback: (httpResponse: HTTPClientResponseData) -> Void) -> HTTPTaskProtocol {
        args = (method: method, URL: URL, body: body, headers: headers)
        let task = MockHTTPTask(mockResponse: mockResponse!, callback: callback)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            task.callback(HTTPClientResponseData(data: task.mockResponse.data, status: task.mockResponse.status, headers: task.mockResponse.headers, error: task.mockResponse.error))
        }
        return task
    }
}

enum MockError: ErrorType {
    case notADictionary
}

class MockSerializer: SerializerProtocol {
    var deserializeArgs: (data: NSData, output: Any.Type)?
    var serializeArg: Any?
    
    func deserializeData(data: NSData, output: Any.Type) throws -> Any {
        deserializeArgs = (data: data, output: output)
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
    
    func serializeToData(object: Any) throws -> NSData {
        serializeArg = object
        return (object as? String ?? "").dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
 */

// Notes:
// HTTPClient must run an a completely different queue or else risks deadlocks when being performed synchronously.
// Add support for multiple serializers in next version.

class RetroluxTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRetroluxSerializerInteraction() {
        // TODO: The front-end API for Retrolux is in flux.
        
//        let client = MockHTTPClient()
//        let expectedResponseBody = "response"
//        let sendBody = "post_body"
//        client.mockResponse = HTTPClientResponseData(data: expectedResponseBody.dataUsingEncoding(NSUTF8StringEncoding), status: 200, headers: ["content-type": "application/json"], error: nil)
//        let serializer = MockSerializer()
//        let r = Retrolux(baseURL: NSURL(string: "https://www.google.com")!, serializer: serializer, httpClient: client)
//        let call = r.POST("/some_endpoint/", body: sendBody, output: String.self)
//        call.perform()
//        
//        guard let serializationArgument = serializer.serializeArg else {
//            XCTFail("Serializer wasn't called.")
//            return
//        }
//        guard let serializationArgString = serializationArgument as? String else {
//            XCTFail("Invalid type of object passed into serializer.")
//            return
//        }
//        XCTAssert(serializationArgString == sendBody, "Wrong data passed to serializer.")
//        
//        guard let deserializationArgs = serializer.deserializeArgs else {
//            XCTFail("Serializer's deserialize function wasn't called.")
//            return
//        }
//        guard let deserializationString = String(data: deserializationArgs.data, encoding: NSUTF8StringEncoding) else {
//            XCTFail("Serializer data appears to have been corrupted somewhere")
//            return
//        }
//        XCTAssert(deserializationString == expectedResponseBody, "Wrong data returned passed into serializer.")
    }
    
    func testRetroluxHTTPClientInteraction() {
//        let client = MockHTTPClient()
        
    }
}
