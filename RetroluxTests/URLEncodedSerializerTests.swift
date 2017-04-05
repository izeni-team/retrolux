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
    func testSerializer() {
        let request = Builder.dry().makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Void.self)
        let body = URLEncodedBody(values: [
            ("Hello", "3"),
            ("Another", "Way"),
            ("Test", "Yay!"),
            ("3+3=", "24/4"),
            ("Another", ""),
            ("", ""),
            ("Misc", "!@#$%^&*()=:/? \"'")
            ])
        let response = request(Body(body)).perform()
        XCTAssert(response.request.httpBody! == "Hello=3&Another=Way&Test=Yay!&3+3%3D=24/4&Another=&=&Misc=!@%23$%25%5E%26*()%3D:/?%20%22'".data(using: .utf8)!)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }
    
    func testSerializerWithNoValues() {
        let request = Builder.dry().makeRequest(method: .post, endpoint: "test", args: Body<URLEncodedBody>(), response: Void.self)
        let body = URLEncodedBody(values: [])
        let response = request(Body(body)).perform()
        XCTAssert(response.request.httpBody! == "".data(using: .utf8)!)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }
    
    func testWithoutBodyWrapper() {
        let request = Builder.dry().makeRequest(method: .post, endpoint: "test", args: URLEncodedBody(), response: Void.self)
        let body = URLEncodedBody(values: [
            ("Hello", "3"),
            ("Another", "Way"),
            ("Test", "Yay!"),
            ("3+3=", "24/4"),
            ("Another", ""),
            ("", ""),
            ("Misc", "!@#$%^&*()=:/? \"'")
            ])
        let response = request(body).perform()
        XCTAssert(response.request.httpBody! == "Hello=3&Another=Way&Test=Yay!&3+3%3D=24/4&Another=&=&Misc=!@%23$%25%5E%26*()%3D:/?%20%22'".data(using: .utf8)!)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }
    
    func testFields() {
        let request = Builder.dry().makeRequest(type: .urlEncoded, method: .post, endpoint: "test", args: (Field("first_name"), Field("last_name")), response: Void.self)
        let response = request((Field("Christopher Bryan"), Field("Henderson"))).perform()
        XCTAssert(response.request.httpBody! == "first_name=Christopher%20Bryan&last_name=Henderson".data(using: .utf8)!)
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }
}
