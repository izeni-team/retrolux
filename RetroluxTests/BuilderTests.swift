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
    var interceptor: ((inout URLRequest) -> Void)? {
        didSet {
            fatalError("Don't set this--it does nothing.")
        }
    }
    
    var credential: URLCredential?
    
    var fakeResponse: ClientResponse!
    
    func makeAsynchronousRequest(request: URLRequest, callback: @escaping (_ response: ClientResponse) -> Void) -> Task {
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

        let function = builder.makeRequest(method: .delete, endpoint: "endpoint", args: (), response: Body<Void>())
        
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
        let request = builder.makeRequest(method: .post, endpoint: "some_endpoint/?query=value a", args: (), response: Body<()>())
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
}
