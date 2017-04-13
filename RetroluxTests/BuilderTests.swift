//
//  BuilderTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import XCTest
import Retrolux

fileprivate class GreedyOutbound<T>: OutboundSerializer {
    enum Error: Swift.Error {
        case whatever
    }
    var forceFail = false
    var supports: Bool?
    var applyWasCalled = false
    
    fileprivate func supports(outboundType: Any.Type) -> Bool {
        supports = outboundType is T.Type || T.self == Any.self
        return supports!
    }
    
    fileprivate func validate(outbound: [BuilderArg]) -> Bool {
        return !forceFail
    }
    
    fileprivate func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        if forceFail {
            throw Error.whatever
        }
        applyWasCalled = true
    }
}

class BuilderTests: XCTestCase {
    func testVoidResponse() {
        let builder = Builder.dummy()
        let request = builder.makeRequest(method: .post, endpoint: "something", args: (), response: Void.self) { (creation, starting, request) in
            ClientResponse(
                url: request.url!,
                data: "Something happened!".data(using: .utf8)!,
                status: 200
                )
        }
        let response = request().perform()
        XCTAssert(response.isSuccessful)
    }
    
    func testAsyncCapturing() {
        let builder = Builder(base: URL(string: "8.8.8.8/")!)
        let request = builder.makeRequest(method: .get, endpoint: "", args: (), response: Void.self)
        let originalURL = builder.base
        let expectation = self.expectation(description: "Waiting for response.")
        request().enqueue { response in
            XCTAssert(response.request.url == originalURL)
            XCTAssert(response.error != nil) // Error should be non-nil, since the builder's dummy baseURL is invalid.
            expectation.fulfill()
        }
        let newURL = URL(string: "8.8.8.8/")!
        builder.base = newURL
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
        
        let expectation2 = self.expectation(description: "Waiting for response.")
        request().enqueue { response in
            XCTAssert(response.request.url == newURL)
            XCTAssert(response.error != nil) // Error should be non-nil, since the builder's dummy baseURL is invalid.
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }
    
    func testURLEscaping() {
        let builder = Builder.dry()
        let request = builder.makeRequest(method: .post, endpoint: "some_endpoint/?query=value a", args: (), response: Void.self)
        let response = request().perform()
        XCTAssert(response.request.url?.absoluteString == "\(builder.base.absoluteString)some_endpoint/%3Fquery=value%20a")
    }
    
    func testOptionalArgs() {
        let builder = Builder.dry()
        
        let arg: Path? = Path("id")
        let request = builder.makeRequest(method: .post, endpoint: "/some_endpoint/{id}/", args: arg, response: Void.self)
        let response = request(Path("it_worked")).perform()
        XCTAssert(response.request.url!.absoluteString.contains("it_worked"))
        
        let arg2: Path? = Path("id")
        let request2 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/{id}/", args: arg2, response: Void.self)
        let response2 = request2(nil).perform()
        XCTAssert(response2.request.url!.absoluteString.removingPercentEncoding!.contains("{id}"))
        
        struct Args3 {
            let field: Field?
        }
        let args3 = Args3(field: Field("username"))
        let request3 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args3, response: Void.self)
        let response3 = request3(Args3(field: Field("IT_WORKED"))).perform()
        let data = response3.request.httpBody!
        let string = String(data: data, encoding: .utf8)!
        XCTAssert(string.contains("IT_WORKED"))
        
        struct Args4 {
            let field: Field?
        }
        let args4 = Args4(field: Field("username"))
        let request4 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args4, response: Void.self)
        let response4 = request4(Args4(field: nil)).perform()
        XCTAssert(response4.request.httpBody == nil)
        
        struct Args5 {
            let field: Field?
            let field2: Field?
            let field3: Field
            let field4: Field?
        }
        let args5 = Args5(field: nil, field2: Field("username"), field3: Field("password"), field4: nil)
        let request5 = builder.makeRequest(method: .post, endpoint: "/some_endpoint/", args: args5, response: Void.self)
        let response5 = request5(Args5(field: nil, field2: Field("TEST_USERNAME"), field3: Field("TEST_PASSWORD"), field4: nil)).perform()
        let data5 = response5.request.httpBody!
        let string5 = String(data: data5, encoding: .utf8)!
        XCTAssert(string5.contains("TEST_USERNAME") && string5.contains("TEST_PASSWORD"))
        
        let args6: Field? = nil
        let request6 = builder.makeRequest(
            method: .post,
            endpoint: "/some_endpoint/",
            args: args6,
            response: Void.self
        )
        let response6 = request6(nil).perform()
        XCTAssert(response6.request.httpBody == nil)
    }
    
    func testDepthRecursion1() {
        @objc(Person)
        class Person: Reflection {
            var name = ""
        }
        
        let call = Builder.dry().makeRequest(method: .post, endpoint: "login", args: (Person()), response: Void.self)
        let response = call((Person())).perform()
        XCTAssert(response.request.httpBody! == "{\"name\":\"\"}".data(using: .utf8)!)
    }
    
    func testMultipleMatchingSerializers() {
        let builder = Builder.dry()
        builder.serializers = [GreedyOutbound<Int>(), GreedyOutbound<String>()]
        let function = builder.makeRequest(method: .post, endpoint: "whatever", args: (Int(), String()), response: Void.self)
        _ = function((3, "a")).perform()
        XCTAssert((builder.serializers[0] as! GreedyOutbound<Int>).applyWasCalled == true)
        XCTAssert((builder.serializers[1] as! GreedyOutbound<String>).applyWasCalled == false)
    }
    
    func testUnsupportedArgument() {
        let builder = Builder.dry()
        builder.serializers = [GreedyOutbound<Int>()]
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: String(), response: Void.self)
        let response = function("a").perform()
        if let error = response.error, case BuilderError.unsupportedArgument(let arg) = error {
            print(arg)
            XCTAssert(arg.type == String.self)
            XCTAssert(arg.creation as? String == "")
            XCTAssert(arg.starting as? String == "a")
        } else {
            XCTFail("Expected to fail.")
        }
    }
    
    func testNestedUnsupportedArgument() {
        struct Container {
            let object = NSObject()
            let arg = String()
            let another = Int()
        }
        
        let builder = Builder.dry()
        builder.serializers = [GreedyOutbound<Int>()]
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: Container(), response: Void.self)
        let response = function(Container()).perform()
        if let error = response.error, case BuilderError.unsupportedArgument(let arg) = error {
            print(arg)
            XCTAssert(arg.type == NSObject.self)
            XCTAssert(arg.creation is NSObject)
            XCTAssert(arg.starting is NSObject)
        } else {
            XCTFail("Expected to fail.")
        }
    }
    
    func testOutboundSerializerValidationError() {
        let builder = Builder.dry()
        let serializer = GreedyOutbound<Int>()
        serializer.forceFail = true
        builder.serializers = [serializer]
        let function = builder.makeRequest(method: .post, endpoint: "whateverz", args: Int(), response: Void.self)
        let response = function(3).perform()
        if let error = response.error, case BuilderError.serializerError(serializer: let s, error: let e, arguments: let args) = error {
            XCTAssert(s === serializer)
            XCTAssert(e is GreedyOutbound<Int>.Error)
            XCTAssert(args.count == 1)
            XCTAssert(args.first?.creation as? Int == Int())
            XCTAssert(args.first?.starting as? Int == 3)
        } else {
            XCTFail("Expected to fail.")
        }
    }
}
