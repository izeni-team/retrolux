//
//  RLObjectJSONSerializerTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import XCTest
@testable import Retrolux
import RetroluxReflector

class ReflectionJSONSerializerTests: XCTestCase {
    func makeResponse(from dictionary: [String: Any]) -> ClientResponse {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        return ClientResponse(data: data, response: nil, error: nil)
    }
    
    func testBasicSendReceive() {
        class Person: Reflection {
            var name = ""
            var age = 0
        }
        
        let serializer = ReflectionJSONSerializer()
        do {
            let response = makeResponse(from: [
                "name": "Bob",
                "age": 24
                ])
            let object = try serializer.makeValue(from: response, type: Person.self)
            
            XCTAssert(object.name == "Bob")
            XCTAssert(object.age == 24)
            
            let url = URL(string: "https://default.thing.any")!
            var request = URLRequest(url: url)
            try serializer.apply(value: object, to: &request)
            XCTAssert(request.url == url, "URL should not have changed")
            XCTAssert(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "Missing Content-Type header.")
            XCTAssert(request.allHTTPHeaderFields?.count == 1, "Only Content-Type should be set.")
            XCTAssert(request.httpBody?.count == "{\"name\":\"Bob\",\"age\":24}".characters.count)
            print("request.httpMethod: \(request.httpMethod)")
            XCTAssert(request.httpMethod == "GET") // Default value is GET--it shouldn't be different.
            
            guard let body = request.httpBody else {
                XCTFail("Missing body on URL request")
                return
            }
            
            guard let dictionary = try JSONSerialization.jsonObject(with: body, options: []) as? [String: Any] else {
                XCTFail("Invalid root type for http body--expected dictionary")
                return
            }
            
            XCTAssert(dictionary["name"] as? String == "Bob")
            XCTAssert(dictionary["age"] as? Int == 24)
        } catch {
            XCTFail("Error: \(error)")
        }
    }
}
