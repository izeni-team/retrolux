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
            let object = try serializer.serialize(from: makeResponse(from: [
                "name": "Bob",
                "age": 35
                ]), type: Person.self)
            
            XCTAssert(object.name == "Bob")
            XCTAssert(object.age == 35)
            
            let data = try serializer.deserialize(from: object, modify: &urlRequest)
            
        } catch {
            print("Error: \(error)")
        }
    }
}
