//
//  PropertyTypeTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

extension RetroluxTests {
    func testPropertyTypeInference() {
        XCTAssert(PropertyType.from(AnyObject) == .anyObject)
        XCTAssert(PropertyType.from(Int?) == .optional(wrapped: .number))
        XCTAssert(PropertyType.from(Bool) == .bool)
        XCTAssert(PropertyType.from(Int) == .number)
        XCTAssert(PropertyType.from(Double) == .number)
        XCTAssert(PropertyType.from(RLObject) == .object(type: RLObject.self))
        XCTAssert(PropertyType.from([Int?]) == .array(type: .optional(wrapped: .number)))
        XCTAssert(PropertyType.from([String: Int?]) == .dictionary(type: .optional(wrapped: .number)))
        XCTAssert(PropertyType.from(NSDictionary) == .dictionary(type: .anyObject))
        XCTAssert(PropertyType.from(NSMutableDictionary) == .dictionary(type: .anyObject))
        let jsonDictionaryData = "{\"test\": true}".data(using: String.Encoding.utf8)!
        let jsonDictionaryType: Any.Type = try! type(of: (JSONSerialization.jsonObject(with: jsonDictionaryData, options: [])))
        XCTAssert(PropertyType.from(jsonDictionaryType) == .dictionary(type: .anyObject))
        XCTAssert(PropertyType.from(NSArray) == .array(type: .anyObject))
        XCTAssert(PropertyType.from(NSMutableArray) == .array(type: .anyObject))
        let jsonArrayData = "[1, 2, 3]".data(using: String.Encoding.utf8)!
        let jsonArrayType: Any.Type = try! type(of: (JSONSerialization.jsonObject(with: jsonArrayData, options: [])))
        XCTAssert(PropertyType.from(jsonArrayType) == .array(type: .anyObject))
        
        class Object2: RLObject {}
        
        class Object1: RLObject {
            dynamic var test = ""
            dynamic var test2 = [String: [Int]]()
            dynamic var test3 = [Object2]()
        }
        
        do {
            let properties = try RLObjectReflector().reflect(Object1())
            let propertyNames = properties.map({ $0.name })
            XCTAssert(propertyNames == [
                "test",
                "test2",
                "test3"
                ])
            let propertyTypes = properties.map({ $0.type })
            XCTAssert(propertyTypes == [
                PropertyType.string,
                PropertyType.dictionary(type: .array(type: .number)),
                PropertyType.array(type: .object(type: Object2.self))
                ])
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
}
