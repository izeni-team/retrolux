//
//  ValueTransformerTests.swift
//  RetroluxReflector
//
//  Created by Christopher Bryan Henderson on 10/17/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import Retrolux

class ValueTransformerTests: XCTestCase {
    func testForwards() {
        class Test: Reflection {
            var name = ""
        }
        
        let dictionary: [String: Any] = [
            "name": "Bob"
        ]
        
        let transformer = ReflectableTransformer(reflector: Reflector())
        XCTAssert(transformer.supports(targetType: Test.self))
        XCTAssert(transformer.supports(value: dictionary, targetType: Test.self, direction: .forwards))
        
        do {
            let test = try transformer.transform(dictionary, targetType: Test.self, direction: .forwards) as? Test
            XCTAssert(test?.name == "Bob")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testBackwards() {
        class Test: Reflection {
            var name = ""
        }
        
        let dictionary: [String: Any] = [
            "name": "bob"
        ]
        
        let transformer = ReflectableTransformer(reflector: Reflector())
        XCTAssert(transformer.supports(targetType: Test.self))
        XCTAssert(transformer.supports(value: dictionary, targetType: Test.self, direction: .forwards))
        
        do {
            let test = Test()
            test.name = "success"
            let dictionary = try transformer.transform(test, targetType: Test.self, direction: .backwards) as? [String: Any]
            XCTAssert(dictionary?["name"] as? String == "success")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNestedBackwards() {
        class Test: Reflection {
            var name = ""
            var age = 0
            var another: Test?
        }
        
        let test = Test()
        test.name = "Bob"
        test.age = 30
        test.another = Test()
        test.another?.name = "Another"
        test.another?.age = 25
        test.another?.another = Test()
        test.another?.another?.name = "Another 2"
        test.another?.another?.age = 20
        
        do {
            let transformer = ReflectableTransformer(reflector: Reflector())
            guard let output = try transformer.transform(test, targetType: Test.self, direction: .backwards) as? [String: Any] else {
                XCTFail("Invalid type returned--expected a dictionary")
                return
            }
            XCTAssert(output["name"] as? String == "Bob")
            XCTAssert(output["age"] as? Int == 30)
            let another = output["another"] as? [String: Any]
            XCTAssert(another?["name"] as? String == "Another")
            XCTAssert(another?["age"] as? Int == 25)
            let another2 = another?["another"] as? [String: Any]
            XCTAssert(another2?["name"] as? String == "Another 2")
            XCTAssert(another2?["age"] as? Int == 20)
            XCTAssert(another2?["another"] is NSNull)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testErrorHandling() {
        class Test: Reflection {
            var name = ""
        }
        
        let dictionary: [String: Any] = [:] // Should trigger a key not found error.
        
        let transformer = ReflectableTransformer(reflector: Reflector())
        
        do {
            _ = try transformer.transform(dictionary, targetType: Test.self, direction: .forwards) as? Test
            XCTFail("Should not have passed.")
        } catch ReflectorSerializationError.keyNotFound(propertyName: let propertyName, key: let key, forClass: let `class`) {
            XCTAssert(propertyName == "name")
            XCTAssert(key == "name")
            XCTAssert(`class` == Test.self)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNullable() {
        class Test: NSObject, Reflectable {
            var date: Date?
            
            required override init() {
                super.init()
            }
            
            static let transformedProperties: [String: Retrolux.ValueTransformer] = [
                "date": DateTransformer.shared
            ]
        }
        
        let test = Test()
        
        let reflection = Reflector()
        
        do {
            let properties = try reflection.reflect(test)
            XCTAssert(properties.count == 1)
            XCTAssert(properties.first?.name == "date")
            let value = try test.value(for: properties.first!)
            XCTAssert(value is NSNull)
        } catch {
            XCTFail("Error getting value: \(error)")
        }
    }
}
