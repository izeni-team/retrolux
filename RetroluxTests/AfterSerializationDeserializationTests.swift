//
//  AfterSerializationDeserializationTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 7/16/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class AfterSerializationDeserializationTests: XCTestCase {
    class Test1: Reflection {
        var test_one = ""
    }
    
    class Test2: Reflection {
        var test_two = ""
    }
    
    class ResultsResponse<T: Reflection>: Reflection {
        var results: [T] = []
        
        override func afterDeserialization(remoteData: [String : Any]) throws {
            results = try Reflector.shared.convert(fromArray: remoteData["results"] as? [[String: Any]] ?? [], to: T.self) as! [T]
        }
        
        override func afterSerialization(remoteData: inout [String: Any]) throws {
            remoteData["results"] = try Reflector.shared.convertToArray(from: results)
        }
        
        override class func config(_ c: PropertyConfig) {
            c["results"] = [.ignored]
        }
    }
    
    func testAfterSerializationAndDeserialization() {
        let builder = Builder.dry()
        
        let request1 = builder.makeRequest(method: .get, endpoint: "", args: ResultsResponse<Test2>(), response: ResultsResponse<Test1>.self) {
            let data = "{\"results\":[{\"test_one\":\"SUCCESS_1\"}]}".data(using: .utf8)!
            return ClientResponse(url: $0.2.url!, data: data, headers: [:], status: 200, error: nil)
        }
        let body2 = ResultsResponse<Test2>()
        let test2 = Test2()
        test2.test_two = "SEND_2"
        body2.results = [
            test2
        ]
        let response1 = request1(body2).perform()
        XCTAssert(response1.request.httpBody == "{\"results\":[{\"test_two\":\"SEND_2\"}]}".data(using: .utf8)!)
        XCTAssert(response1.body?.results.first?.test_one == "SUCCESS_1")
        
        let request2 = builder.makeRequest(method: .get, endpoint: "", args: ResultsResponse<Test1>(), response: ResultsResponse<Test2>.self) {
            let data = "{\"results\":[{\"test_two\":\"SUCCESS_2\"}]}".data(using: .utf8)!
            return ClientResponse(url: $0.2.url!, data: data, headers: [:], status: 200, error: nil)
        }
        let body1 = ResultsResponse<Test1>()
        let test1 = Test1()
        test1.test_one = "SEND_1"
        body1.results = [
            test1
        ]
        let response2 = request2(body1).perform()
        XCTAssert(response2.request.httpBody == "{\"results\":[{\"test_one\":\"SEND_1\"}]}".data(using: .utf8)!)
        XCTAssert(response2.body?.results.first?.test_two == "SUCCESS_2")
    }
}
