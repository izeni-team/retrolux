//
//  PropertyTransformerTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class PropertyTransformerTests: XCTestCase {
    func testObjectTransformer() {
        class Test: RLObject {
            var name = ""
            var another: Test?
        }
        
        do {
            let test = Test()
            let properties = try RLObjectReflector().reflect(test)
            XCTAssert(properties.count == 2)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.last?.name == "another")
            XCTAssert(properties.first?.transformer == nil)
            XCTAssert(properties.last?.transformer != nil)
            
            guard let transformer = properties.last?.transformer else {
                XCTFail("Failed to find transformer on property \"another\"")
                return
            }
            
            let dictionary: [String: Any] = [
                "name": "Bryan",
                "another": [
                    "name": "KARMA"
                ]
            ]
            
            XCTAssert(transformer.supports(type: Test.self, direction: .forwards))
            XCTAssert(transformer.supports(type: [String: Any].self, direction: .backwards))
            XCTAssert(transformer.supports(value: test, direction: .forwards))
            XCTAssert(transformer.supports(value: dictionary, direction: .backwards))
            
            let another = try transformer.transform(dictionary["another"], direction: .forwards) as? Test
            XCTAssert(another?.name == "KARMA")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
