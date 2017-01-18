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

func plist(_ key: String) -> String {
    // http://stackoverflow.com/a/38035382/2406857
    let bundle = Bundle(for: BuilderTests.self)
    let path = bundle.path(forResource: "Sensitive", ofType: "plist")!
    let url = URL(fileURLWithPath: path)
    let data = try! Data(contentsOf: url)
    let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
    let dictionary = plist as! [String: Any]
    return dictionary[key] as! String
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
    
    func testDigestAuth() {
        class MyBuilder: Builder {
            let baseURL = URL(string: plist("URL"))!
            let client: Client = HTTPClient()
            let callFactory: CallFactory = HTTPCallFactory()
            let serializers: [Serializer] = [
                ReflectionJSONSerializer(),
                URLEncodedSerializer()
            ]
        }
        
        let builder = MyBuilder()
        
        builder.client.interceptor = { request in
            func md5(_ string: String) -> String {
                var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
                
                let data = string.data(using: .utf8)!
                _ = data.withUnsafeBytes { bytes in
                    CC_MD5(bytes, CC_LONG(data.count), &digest)
                }
                
                var digestHex = ""
                for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
                    digestHex += String(format: "%02x", digest[index])
                }
                
                return digestHex
            }
            
            // Algorithm for RFC 2069 taken from:
            // https://en.wikipedia.org/wiki/Digest_access_authentication
            let username = plist("DigestUsername")
            let realm = plist("DigestRealm")
            let password = plist("DigestPassword")
            let ha1 = md5("\(username):\(realm):\(password)")
            
            let method = "\(request.httpMethod ?? "")"
            let digestURI: String = {
                var url = "/"
                url += request.url!.absoluteString
                url = url.replacingOccurrences(of: builder.baseURL.absoluteString, with: "")
                url = url.removingPercentEncoding!
                return url
            }()
            let ha2 = md5("\(method):\(digestURI)")
            
            let nonce = ""
            let response = md5("\(ha1):\(nonce):\(ha2)")
            
            let headerValue = "Digest username=\"\(username)\", realm=\"\(realm)\", nonce=\"\(nonce)\", uri=\"\(digestURI)\", response=\"\(response)\", opaque=\"\""
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }
        
        let request = builder.makeRequest(method: .post, endpoint: "online/api/v2/app/login", args: Body<URLEncodedBody>(), response: Body<Void>())
        let expectation = self.expectation(description: "Waiting for network callback")
        let params = URLEncodedBody(values: [
            ("username", plist("username")),
            ("password", plist("password"))
            ])
        request(Body(params)).enqueue { (response: Response<Void>) in
            let status = response.raw?.status ?? 0
            XCTAssert(status == 200)
            print("HTTP \(status)")
            if status != 200 {
                if let data = response.raw?.data {
                    print("\n--- TEST FAILURE ---")
                    let string = String(data: data, encoding: .utf8)!
                    print("1: \(string)")
                    print("--- TEST FAILURE ---\n")
                }
                XCTFail("Unexpected status code of \(status)")
            } else {
                let pubs = builder.makeRequest(method: .get, endpoint: "online/api/v2/app/publications", args: (), response: Body<Void>())
                pubs().enqueue { (response: Response<Void>) in
                    let status2 = response.raw?.status ?? 0
                    print("HTTP \(status2)")
                    XCTAssert(status2 == 200)
                    if status2 != 200 {
                        if let data = response.raw?.data {
                            print("\n--- TEST FAILURE ---")
                            let string = String(data: data, encoding: .utf8)!
                            print("2: \(string)")
                            print("--- TEST FAILURE ---\n")
                        }
                    }
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5) { (error) in
            if let error = error {
                XCTFail("Failed to wait for expectation: \(error)")
            }
        }
    }
}
