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
    func makeResponse(from jsonObject: Any) -> ClientResponse {
        let data = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return ClientResponse(data: data, response: nil, error: nil)
    }
    
    func makeEmptyURLRequest() -> URLRequest {
        let url = URL(string: "https://default.thing.any")!
        return URLRequest(url: url)
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
            
            var request = makeEmptyURLRequest()
            let originalURL = request.url!
            try serializer.apply(value: object, to: &request)
            XCTAssert(request.url == originalURL, "URL should not have changed")
            XCTAssert(request.value(forHTTPHeaderField: "Content-Type") == "application/json", "Missing Content-Type header.")
            XCTAssert(request.allHTTPHeaderFields?.count == 1, "Only Content-Type should be set.")
            XCTAssert(request.httpBody?.count == "{\"name\":\"Bob\",\"age\":24}".characters.count)
            XCTAssert(request.httpMethod == "GET", "Default value should be GET, but the serializer changed it to \(request.httpMethod).")
            
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
    
    func testSupports() {
        class NotSupported: NSObject {}
        class Supported: Reflection {}
        class AlsoSupported: NSObject, Reflectable {
            override required init() {
                super.init()
            }
        }
        
        let serializer = ReflectionJSONSerializer()
        XCTAssert(serializer.supports(type: NotSupported.self) == false)
        XCTAssert(serializer.supports(type: Supported.self) == true)
        XCTAssert(serializer.supports(type: AlsoSupported.self) == true)
    }
    
    func testToJSONError() {
        class Invalid: Reflection {
            var name = Data() // This is not a supported type
        }
        
        let serializer = ReflectionJSONSerializer()
        var request = makeEmptyURLRequest()
        
        do {
            try serializer.apply(value: Invalid(), to: &request)
            XCTFail("Should not have succeeded.")
        } catch ReflectionError.unsupportedPropertyValueType(let property, let valueType, let forClass) {
            XCTAssert(property == "name")
            XCTAssert(valueType == Data.self)
            XCTAssert(forClass == Invalid.self)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        
        do {
            try serializer.apply(value: [Invalid()], to: &request)
            XCTFail("Should not have succeeded.")
        } catch ReflectionError.unsupportedPropertyValueType(let property, let valueType, let forClass) {
            XCTAssert(property == "name")
            XCTAssert(valueType == Data.self)
            XCTAssert(forClass == Invalid.self)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testFromJSONError() {
        class Valid: Reflection {
            var age: Int = 0
        }
        
        let serializer = ReflectionJSONSerializer()
        let inputDictionary = [
            "age": "0" // Is wrong type on purpose
        ]
        
        do {
            let response = makeResponse(from: inputDictionary)
            _ = try serializer.makeValue(from: response, type: Valid.self)
            XCTFail("Should not have succeeded.")
        } catch SerializationError.typeMismatch(expected: let expected, got: _, property: let property, forClass: let forClass) {
            XCTAssert(expected == .number)
            XCTAssert(property == "age")
            XCTAssert(forClass == Valid.self)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        
        do {
            let response = makeResponse(from: [inputDictionary])
            _ = try serializer.makeValue(from: response, type: [Valid].self)
            XCTFail("Should not have succeeded.")
        } catch SerializationError.typeMismatch(expected: let expected, got: _, property: let property, forClass: let forClass) {
            XCTAssert(expected == .number)
            XCTAssert(property == "age")
            XCTAssert(forClass == Valid.self)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testNoDataError() {
        class Whatever: Reflection {}
        
        let serializer = ReflectionJSONSerializer()
        let clientData = ClientResponse(data: nil, response: nil, error: nil)
        
        do {
            _ = try serializer.makeValue(from: clientData, type: Whatever.self)
            XCTFail("Should not have passed.")
        } catch ReflectionJSONSerializerError.noData {
            // Works!
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testInvalidJSON() {
        class Whatever: Reflection {}
        
        let serializer = ReflectionJSONSerializer()
        let clientData = ClientResponse(data: "{".data(using: .utf8), response: nil, error: nil)
        
        do {
            _ = try serializer.makeValue(from: clientData, type: Whatever.self)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.invalidJSON {
            // Works!
        } catch {
            XCTFail("Failed with error \(error)")
        }
        
        do {
            _ = try serializer.makeValue(from: clientData, type: [Whatever].self)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.invalidJSON {
            // Works!
        } catch {
            XCTFail("Failed with error \(error)")
        }
    }
    
    func testUnsupportedType() {
        let serializer = ReflectionJSONSerializer()
        let clientData = ClientResponse(data: "asdf".data(using: .utf8), response: nil, error: nil)
        var request = makeEmptyURLRequest()
        
        // Test array nested type.
        
        do {
            _ = try serializer.makeValue(from: clientData, type: [String].self)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.unsupportedType(let type) {
            XCTAssert(type == [String].self)
        } catch {
            XCTFail("Unknown error: \(error)")
        }
        
        do {
            _ = try serializer.apply(value: [0], to: &request)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.unsupportedType(let type) {
            XCTAssert(type == [Int].self)
        } catch {
            XCTFail("Unknown error: \(error)")
        }
        
        // Test individual type.
        
        do {
            _ = try serializer.makeValue(from: clientData, type: String.self)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.unsupportedType(let type) {
            XCTAssert(type == String.self)
        } catch {
            XCTFail("Unknown error: \(error)")
        }
        
        do {
            _ = try serializer.apply(value: 0, to: &request)
            XCTFail("Should not have succeeded.")
        } catch ReflectionJSONSerializerError.unsupportedType(let type) {
            XCTAssert(type == Int.self)
        } catch {
            XCTFail("Unknown error: \(error)")
        }
    }
}
