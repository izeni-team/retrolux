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

fileprivate func toJSONData(_ value: Any) -> Data {
    return try! JSONSerialization.data(withJSONObject: value, options: [])
}

class RLObjectJSONSerializerTests: XCTestCase {
    func testBasicSerialization() {
        class Car: RLObject {
            var make = ""
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let responseData = toJSONData([
            "make": "Honda",
            "model": "Civic",
            "year": 1988,
            "dealership": true
        ])
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        
        do {
            let car: Car = try serializer.serialize(from: response)
            XCTAssert(car.make == "Honda")
            XCTAssert(car.model == "Civic")
            XCTAssert(car.year == 1988)
            XCTAssert(car.dealership == true)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
    
    func testNullableSerialization() {
        class Car: RLObject {
            var make: String? = "wrong"
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let responseData = toJSONData([
            "make": NSNull(),
            "model": NSNull(),
            "year": 1988,
            "dealership": true
            ])
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        
        do {
            let car: Car = try serializer.serialize(from: response)
            XCTAssert(car.make == "Honda")
            XCTAssert(car.model == "Civic")
            XCTAssert(car.year == 1988)
            XCTAssert(car.dealership == true)
        } catch RLObjectReflectionError.unsupportedPropertyValueType(property: <#T##String#>, valueType: <#T##Any.Type#>, forClass: <#T##Any.Type#>)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
}
