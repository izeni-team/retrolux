//
//  InterpretedResponseTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class InterpretedResponseTests: XCTestCase {
    func testUnsupportedArg() {
        let expectation = self.expectation(description: "Waiting for response")
        
        let builder = Builder(base: URL(string: "http://www.google.com/")!)
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 200, data: nil)
        }
        let function = builder.makeRequest(method: .get, endpoint: "whateverz", args: 1, response: Void.self)
        function(2).enqueue { response in
            switch response.interpreted {
            case .success(_):
                XCTFail("Should not have succeeded.")
            case .failure(let error):
                if case BuilderError.unsupportedArgument(let arg) = error {
                    XCTAssert(arg.creation as? Int == 1)
                    XCTAssert(arg.starting as? Int == 2)
                    XCTAssert(arg.type == Int.self)
                } else {
                    XCTFail("Wrong error returned: \(error); expected an unsupported argument error instead.")
                }
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testInvalidHttpStatusCode() {
        let expectation = self.expectation(description: "Waiting for response")
        
        class Person: Reflection {
            var name: String = ""
            
            required init() {
                
            }
            
            init(name: String) {
                self.name = name
            }
        }
        
        let builder = Builder(base: URL(string: "http://127.0.0.1/")!)
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 400, data: "{\"name\":null}".data(using: .utf8)!)
        }
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: Person(name: "Alice"), response: Person.self)
        function(Person(name: "Bob")).enqueue { response in
            switch response.interpreted {
            case .success(_):
                XCTFail("Should not have succeeded.")
            case .failure(let error):
                if case ResponseError.invalidHttpStatusCode(code: let code) = error {
                    XCTAssert(code == 400)
                } else {
                    XCTFail("Wrong error returned: \(error); expected an invalid HTTP status code error instead.")
                }
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testResponseSerializationError() {
        let expectation = self.expectation(description: "Waiting for response")
        
        class Person: Reflection {
            var name: String = ""
        }
        
        let builder = Builder(base: URL(string: "http://127.0.0.1/")!)
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 200, data: "{\"name\":null}".data(using: .utf8)!)
        }
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: (), response: Person.self)
        function().enqueue { response in
            switch response.interpreted {
            case .success(_):
                XCTFail("Should not have succeeded.")
            case .failure(let error):
                if case SerializationError.propertyDoesNotSupportNullValues(property: let property, forClass: let `class`) = error {
                    XCTAssert(property.name == "name")
                    XCTAssert(`class` == Person.self)
                } else {
                    XCTFail("Wrong error returned: \(error).")
                }
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testSuccess() {
        let expectation = self.expectation(description: "Waiting for response")
        
        class Person: Reflection {
            var name: String = ""
        }
        
        let builder = Builder(base: URL(string: "http://127.0.0.1/")!)
        builder.responseInterceptor = { response in
            response = ClientResponse(base: response, status: 200, data: "{\"name\":\"bobby\"}".data(using: .utf8)!)
        }
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: (), response: Person.self)
        function().enqueue { response in
            switch response.interpreted {
            case .success(let person):
                XCTAssert(person.name == "bobby")
            case .failure(let error):
                XCTFail("Response interpreted as failure: \(error)")
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
