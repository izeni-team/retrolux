//
//  BuilderTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import XCTest
import Retrolux

fileprivate class FakeTask: Task {
    var cancelled = false
    var resumed = false
    
    func cancel() {
        cancelled = true
    }
    
    func resume() {
        resumed = true
    }
}

fileprivate class FakeClient: Client {
    fileprivate var requestInterceptor: ((inout URLRequest) -> Void)?
    fileprivate var responseInterceptor: ((inout ClientResponse) -> Void)?
    
    var credential: URLCredential?
    
    var fakeResponse: ClientResponse!
    
    func makeAsynchronousRequest(request: inout URLRequest, callback: @escaping (_ response: ClientResponse) -> Void) -> Task {
        assert(fakeResponse != nil)
        let task = FakeTask()
        DispatchQueue.main.async {
            callback(self.fakeResponse)
        }
        return task
    }
}

fileprivate class FakeCall<T>: Call<T> {
    fileprivate var delegatedStart: (@escaping (Response<T>) -> Void) -> Void
    fileprivate var delegatedCancel: () -> Void
    
    init(start: @escaping (@escaping (Response<T>) -> Void) -> Void, cancel: @escaping () -> Void) {
        self.delegatedStart = start
        self.delegatedCancel = cancel
        super.init()
    }
    
    override func enqueue(callback: @escaping (Response<T>) -> Void) {
        delegatedStart(callback)
    }
    
    override func cancel() {
        delegatedCancel()
    }
}

fileprivate class FakeCallFactory: CallFactory {
    func makeCall<T>(start: @escaping (@escaping (Response<T>) -> Void) -> Void, cancel: @escaping () -> Void) -> Call<T> {
        return FakeCall(start: start, cancel: cancel)
    }
}

fileprivate class FakeBuilder: Builder {
    let baseURL: URL
    let client: Client
    let callFactory: CallFactory
    let serializers: [Serializer]
    
    init() {
        self.baseURL = URL(string: "https://www.google.com/")!
        self.client = FakeClient()
        self.callFactory = FakeCallFactory()
        self.serializers = [ReflectionJSONSerializer()]
    }
}

fileprivate class RealBuilder: Builder {
    let baseURL: URL
    let client: Client
    let callFactory: CallFactory
    let serializers: [Serializer]
    
    init() {
        self.baseURL = URL(string: "https://www.google.com/")!
        self.client = HTTPClient()
        self.callFactory = HTTPCallFactory()
        self.serializers = [ReflectionJSONSerializer()]
    }
}

class BuilderTests: XCTestCase {
    func testStartAndCancelCalls() {
        let builder = FakeBuilder()
        (builder.client as! FakeClient).fakeResponse = ClientResponse(data: nil, response: nil, error: nil)

        let function = builder.makeRequest(method: .delete, endpoint: "endpoint", args: (), response: Void.self)
        
        let call = function() as! FakeCall<()>
        
        let oldStart = call.delegatedStart
        var startCalled = 0
        call.delegatedStart = { response in
            startCalled += 1
            oldStart(response)
        }
        
        let oldCancel = call.delegatedCancel
        var cancelCalled = 0
        call.delegatedCancel = {
            cancelCalled += 1
            oldCancel()
        }
        
        let expectation = self.expectation(description: "Waiting for network callback")
        
        call.enqueue { response in
            XCTAssert(startCalled == 1)
            XCTAssert(cancelCalled == 0)
            
            call.cancel()
            XCTAssert(cancelCalled == 1)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed to wait for expectation: \(error)")
            }
        }
    }
    
    func testURLEscaping() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .post, endpoint: "some_endpoint/?query=value a", args: (), response: Void.self)
        let expectation = self.expectation(description: "Waiting for response")
        request().enqueue { response in
            XCTAssert(response.request.url?.absoluteString == "http://127.0.0.1/some_endpoint/%3Fquery=value%20a")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testOptionalArgs() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        
        let arg: Path? = Path("id")
        let request = builder.makeRequest(method: .post, endpoint: "/some_endpoint/{id}/", args: arg, response: Void.self)
        let expectation = self.expectation(description: "Waiting for response")
        request(Path("it_worked")).enqueue { response in
            XCTAssert(response.request.url!.absoluteString.contains("it_worked"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        let arg2: Path? = Path("id")
        let request2 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/{id}/", args: arg2, response: Void.self)
        let expectation2 = self.expectation(description: "Waiting for response")
        request2(nil).enqueue { response in
            XCTAssert(response.request.url!.absoluteString.removingPercentEncoding!.contains("{id}"))
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        struct Args3 {
            let field: Field?
        }
        let args3 = Args3(field: Field("username"))
        let request3 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args3, response: Void.self)
        let expectation3 = self.expectation(description: "Waiting for response")
        request3(Args3(field: Field("IT_WORKED"))).enqueue { response in
            let data = response.request.httpBody!
            let string = String(data: data, encoding: .utf8)!
            XCTAssert(string.contains("IT_WORKED"))
            
            expectation3.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        struct Args4 {
            let field: Field?
        }
        let args4 = Args4(field: Field("username"))
        let request4 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args4, response: Void.self)
        let expectation4 = self.expectation(description: "Waiting for response")
        request4(Args4(field: nil)).enqueue { response in
            XCTAssert(response.request.httpBody == nil)
            expectation4.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        struct Args5 {
            let field: Field?
            let field2: Field?
            let field3: Field
            let field4: Field?
        }
        let args5 = Args5(field: nil, field2: Field("username"), field3: Field("password"), field4: nil)
        let request5 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args5, response: Void.self)
        let expectation5 = self.expectation(description: "Waiting for response")
        request5(Args5(field: nil, field2: Field("TEST_USERNAME"), field3: Field("TEST_PASSWORD"), field4: nil)).enqueue { response in
            let data = response.request.httpBody!
            let string = String(data: data, encoding: .utf8)!
            XCTAssert(string.contains("TEST_USERNAME") && string.contains("TEST_PASSWORD"))
            
            expectation5.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        let args6: Field? = nil
        let request6 = builder.makeRequest(
            method: .post,
            endpoint: "/some_endpoint/",
            args: args6,
            response: Void.self
        )
        
        let expectation6 = self.expectation(description: "Waiting for response")
        
        request6(nil).enqueue { response in
            XCTAssert(response.request.httpBody == nil)
            
            expectation6.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
