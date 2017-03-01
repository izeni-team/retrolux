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
    func makeDummyBuilder() -> Builder {
        return RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
    }
    
    func testSerializer() {
        let builder = makeDummyBuilder()
        let request = builder.makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Void.self)
        let body = URLEncodedBody(values: [
            ("Hello", "3"),
            ("Another", "Way"),
            ("Test", "Yay!"),
            ("3+3=", "24/4"),
            ("Another", ""),
            ("", ""),
            ("Misc", "!@#$%^&*()=:/? \"'")
            ])
        
        let expectation = self.expectation(description: "request.enqueue")
        request(Body(body)).enqueue { (response: Response<Void>) in
            XCTAssert(response.request.httpBody! == "Hello=3&Another=Way&Test=Yay!&3+3%3D=24/4&Another=&=&Misc=!@%23$%25%5E%26*()%3D:/?%20%22'".data(using: .utf8)!)
            XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
    
    func testSerializerWithNoValues() {
        let builder = makeDummyBuilder()
        let request = builder.makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Void.self)
        let body = URLEncodedBody(values: [])
        let expectation = self.expectation(description: "request.enqueue")
        request(Body(body)).enqueue { (response: Response<Void>) in
            XCTAssert(response.request.httpBody! == "".data(using: .utf8)!)
            XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
    
    func testWithoutBodyWrapper() {
        let builder = makeDummyBuilder()
        let request = builder.makeRequest(method: .post, endpoint: "test", args: URLEncodedBody(), response: Void.self)
        let body = URLEncodedBody(values: [
            ("Hello", "3"),
            ("Another", "Way"),
            ("Test", "Yay!"),
            ("3+3=", "24/4"),
            ("Another", ""),
            ("", ""),
            ("Misc", "!@#$%^&*()=:/? \"'")
            ])
        let expectation = self.expectation(description: "request.enqueue")
        request(body).enqueue { (response: Response<Void>) in
            XCTAssert(response.request.httpBody! == "Hello=3&Another=Way&Test=Yay!&3+3%3D=24/4&Another=&=&Misc=!@%23$%25%5E%26*()%3D:/?%20%22'".data(using: .utf8)!)
            XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
    
    func testFields() {
        let builder = makeDummyBuilder()
        let request = builder.makeRequest(type: .urlEncoded, method: .post, endpoint: "test", args: (Field("first_name"), Field("last_name")), response: Void.self)
        let expectation = self.expectation(description: "request.enqueue")
        request((Field("Christopher Bryan"), Field("Henderson"))).enqueue { (response: Response<Void>) in
            XCTAssert(response.request.httpBody! == "first_name=Christopher%20Bryan&last_name=Henderson".data(using: .utf8)!)
            XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
}
