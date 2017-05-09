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
            var test: Test?
            
            override class func config(_ c: PropertyConfig) {
                c["test"] = [.nullable]
            }
        }
        
        let dictionary: [String: Any] = [
            "name": "Bob"
        ]
        
        let reflector = Reflector()
        let transformer = ReflectableTransformer(weakReflector: reflector)
        
        do {
            let test = Test()
            let config = PropertyConfig()
            Test.config(config)
            let property = Property(type: .unknown(Test.self), name: "test", options: config["test"])
            try transformer.set(value: dictionary, for: property, instance: test)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNested() {
        class Test: Reflection {
            var name = ""
            var friends: [String: Test]? = nil
            
            convenience init(name: String) {
                self.init()
                self.name = name
            }
        }
        
        let reflector = Reflector()
        let transformer = ReflectableTransformer(weakReflector: reflector)
        XCTAssert(transformer.supports(propertyType: .unknown(Test.self)))
        
        do {
            let test = Test()
            test.name = "bob"
            let dictionary = try reflector.convertToDictionary(from: test)
            XCTAssert(dictionary["name"] as? String == "bob")
            XCTAssert(dictionary["friends"] is NSNull)
            
            test.friends = [
                "sally": Test(name: "Sally"),
                "robert": Test(name: "Robert")
            ]
            let d2 = try reflector.convertToDictionary(from: test)
            XCTAssert(d2["name"] as? String == "bob")
            
            let friends = d2["friends"] as? [String: Any]
            
            let sally = friends?["sally"] as? [String: Any]
            XCTAssert(sally?["name"] as? String == "Sally")
            
            let robert = friends?["robert"] as? [String: Any]
            XCTAssert(robert?["name"] as? String == "Robert")
            
            let back = try reflector.convert(fromDictionary: d2, to: Test.self) as! Test
            XCTAssert(back.name == "bob")
            XCTAssert(back.friends?.count == 2)
            XCTAssert(back.friends?["sally"]?.name == "Sally")
            XCTAssert(back.friends?["robert"]?.name == "Robert")
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
            let reflector = Reflector()
            let transformer = ReflectableTransformer(weakReflector: reflector)
            let output = try transformer.getter(test)
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
        
        let reflector = Reflector()
        let transformer = ReflectableTransformer(weakReflector: reflector)
        
        do {
            _ = try transformer.setter(dictionary, type: Test.self)
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
        class CustomTransformer: NestedTransformer {
            typealias TypeOfData = String
            typealias TypeOfProperty = Data
            
            func setter(_ dataValue: String, type: Any.Type) throws -> Data {
                XCTFail("Shouldn't be called.")
                return Data()
            }
            
            func getter(_ propertyValue: Data) throws -> String {
                XCTFail("Shouldn't be called.")
                return ""
            }
        }
        
        class Test: NSObject, Reflectable {
            var data: Data?
            
            required override init() {
                super.init()
            }
            
            static func config(_ c: PropertyConfig) {
                c["data"] = [.transformed(CustomTransformer())]
            }
        }
        
        let test = Test()
        
        let reflector = Reflector()
        
        do {
            let properties = try reflector.reflect(test)
            XCTAssert(properties.count == 1)
            XCTAssert(properties.first?.name == "data")
            let value = try reflector.value(for: properties.first!, on: test)
            XCTAssert(value is NSNull)
        } catch {
            XCTFail("Error getting value: \(error)")
        }
    }
    
    func testBoolStringConversion() {
        class BoolTransformer: NestedTransformer {
            static var setterWasCalled = 0
            static var getterWasCalled = 0
            
            typealias TypeOfData = String
            typealias TypeOfProperty = Bool
            
            func setter(_ dataValue: String, type: Any.Type) throws -> Bool {
                BoolTransformer.setterWasCalled += 1
                return dataValue == "t"
            }
            
            func getter(_ propertyValue: Bool) throws -> String {
                BoolTransformer.getterWasCalled += 1
                return propertyValue ? "t" : "f"
            }
        }
        
        class Test: Reflection {
            var randomize: Bool = false
            
            override class func config(_ c: PropertyConfig) {
                c["randomize"] = [.transformed(BoolTransformer())]
            }
        }
        
        let reflector = Reflector()
        do {
            XCTAssert(BoolTransformer.setterWasCalled == 0)
            XCTAssert(BoolTransformer.getterWasCalled == 0)
            
            let data = "{\"randomize\":\"t\"}".data(using: .utf8)!
            let test = try reflector.convert(fromJSONDictionaryData: data, to: Test.self) as! Test
            XCTAssert(test.randomize == true)
            
            XCTAssert(BoolTransformer.setterWasCalled == 1)
            XCTAssert(BoolTransformer.getterWasCalled == 0)
            
            let data2 = "{\"randomize\":\"f\"}".data(using: .utf8)!
            let test2 = try reflector.convert(fromJSONDictionaryData: data2, to: Test.self) as! Test
            XCTAssert(test2.randomize == false)
            
            XCTAssert(BoolTransformer.setterWasCalled == 2)
            XCTAssert(BoolTransformer.getterWasCalled == 0)
            
            let output = try reflector.convertToJSONDictionaryData(from: test)
            XCTAssert(output == "{\"randomize\":\"t\"}".data(using: .utf8)!)
            
            XCTAssert(BoolTransformer.setterWasCalled == 2)
            XCTAssert(BoolTransformer.getterWasCalled == 1)

            let output2 = try reflector.convertToJSONDictionaryData(from: test2)
            XCTAssert(output2 == "{\"randomize\":\"f\"}".data(using: .utf8)!)
            
            XCTAssert(BoolTransformer.setterWasCalled == 2)
            XCTAssert(BoolTransformer.getterWasCalled == 2)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
