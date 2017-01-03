//
//  URLEncodedSerializerTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/2/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class URLEncodedSerializerTests: XCTestCase {
    // TODO: Use a fake HTTP client that doesn't actually hit google.com.
    private class URLEncodedBuilder: Builder {
        let baseURL: URL = URL(string: "https://www.google.com/")!
        let client: Client = HTTPClient()
        let callFactory: CallFactory = HTTPCallFactory()
        let serializers: [Serializer] = [
            URLEncodedSerializer(),
            ReflectionJSONSerializer(),
        ]
    }
    
    func testSerializer() {
        var hasRunInterceptor = false
        let builder = URLEncodedBuilder()
        builder.client.interceptor = { request in
            XCTAssert(request.httpBody! == "Hello=3&Another=Way&Test=Yay!&3+3%3D=24/6&Another=&=&Misc=!@%23$%25%5E%26*()%3D:/?%22\'".data(using: .utf8)!)
            XCTAssert(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            hasRunInterceptor = true
        }
        let request = builder.makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Body<Void>())
        let body = URLEncodedBody(values: [
            ("Hello", "3"),
            ("Another", "Way"),
            ("Test", "Yay!"),
            ("3+3=", "24/6"),
            ("Another", ""),
            ("", ""),
            ("Misc", "!@#$%^&*()=:/?\"'")
            ])
        
        let expectation = self.expectation(description: "request.enqueue")
        request(Body(body)).enqueue { (response: Response<Void>) in
            XCTAssert(hasRunInterceptor)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
    
    func testSerializerWithNoValues() {
        var hasRunInterceptor = false
        let builder = URLEncodedBuilder()
        builder.client.interceptor = { request in
            XCTAssert(request.httpBody! == "".data(using: .utf8)!)
            XCTAssert(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            hasRunInterceptor = true
        }
        let request = builder.makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Body<Void>())
        let body = URLEncodedBody(values: [])
        
        let expectation = self.expectation(description: "request.enqueue")
        request(Body(body)).enqueue { (response: Response<Void>) in
            XCTAssert(hasRunInterceptor)
            expectation.fulfill()
        }
        
        // TODO: Use a fake HTTP client that doesn't actually hit google.com.
        // TODO: Stop waiting 5 seconds for timeout, since that's too much--test shouldn't depend on network.
        self.waitForExpectations(timeout: 5) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
}
