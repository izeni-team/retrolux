//
//  ReflectionTests.swift
//  RetroluxReflector
//
//  Created by Christopher Bryan Henderson on 10/17/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import Retrolux

class ReflectionTests: XCTestCase {
    func setPropertiesHelper(_ properties: [Property], dictionary: [String: Any], instance: Reflectable) {
        XCTAssert(Set(properties.map({ $0.name })) == Set(dictionary.keys))
        
        for property in properties {
            do {
                try instance.set(value: dictionary[property.name], for: property)
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        for property in properties {
            let value = dictionary[property.mappedTo] as? NSObject
            XCTAssert(try! instance.value(for: property) as? NSObject == value || !property.required)
        }
    }
    
    func testRLObjectBasicSerialization() {
        class Model: Reflection {
            var name = ""
            var age = 0
            var whatever = false
            var meta = [String: String]()
            var model: Model?
        }
        
        let dictionary = [
            "name": "Brian",
            "age": 23,
            "whatever": true,
            "meta": [
                "place_of_birth": "Bluffdale, UT",
                "height": "5' 7\""
            ],
            "model": NSNull()
            ] as [String : Any]
        
        do {
            let model = Model()
            let properties = try Reflector().reflect(model)
            setPropertiesHelper(properties, dictionary: dictionary, instance: model)
        }
        catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectIgnoredProperties() {
        class Object: Reflection {
            var name = ""
            var age = 0
            
            override class var ignoredProperties: [String] {
                return ["name"]
            }
        }
        
        do {
            let properties = try Reflector().reflect(Object())
            XCTAssert(Set(properties.map({ $0.name })) == Set(["age"]))
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectIgnoredErrorsForProperties() {
        class Object: Reflection {
            var name = "default_value"
            var age = 0
            
            override class var ignoreErrorsForProperties: [String] {
                return ["name"]
            }
        }
        
        do {
            let object = Object()
            let properties = try Reflector().reflect(object)
            guard let nameProp = properties.filter({ $0.name == "name" }).first else {
                XCTFail("Name property was missing")
                return
            }
            try object.set(value: NSNull(), forProperty: nameProp)
            XCTAssert(object.name == "default_value")
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectMappedProperties() {
        class Object: Reflection {
            var description_ = ""
            
            override class var mappedProperties: [String: String] {
                return ["description_": "description"]
            }
        }
        
        do {
            let properties = try Reflector().reflect(Object())
            let prop = properties.first
            XCTAssert(properties.count == 1 && prop?.mappedTo == "description" && prop?.name == "description_")
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    /*
     Tests that inheritance is properly supported when the base class is Reflection.
     */
    func testRLObjectInheritance() {
        class Plain: Reflection {
            var bad = ""
            
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "bad", forProperty: property)
            }
            
            override func value(for property: Property) throws -> Any? {
                return "bad"
            }
            
            override func validate() -> String? {
                return "bad"
            }
            
            override class var ignoredProperties: [String] {
                return ["bad"]
            }
            
            override class var ignoreErrorsForProperties: [String] {
                return ["bad"]
            }
            
            override class var mappedProperties: [String: String] {
                return ["bad": "bad"]
            }
            
            override class var transformedProperties: [String: Retrolux.ValueTransformer] {
                return ["bad": ReflectableTransformer(reflector: Reflector())]
            }
        }
        
        class Problematic: Plain {
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "good", forProperty: property)
            }
            
            override func value(for property: Property) throws -> Any? {
                return "good"
            }
            
            override func validate() -> String? {
                return "good"
            }
            
            override class var ignoredProperties: [String] {
                return ["good"]
            }
            
            override class var ignoreErrorsForProperties: [String] {
                return ["good"]
            }
            
            override class var mappedProperties: [String: String] {
                return ["good": "good"]
            }
            
            override class var transformedProperties: [String: Retrolux.ValueTransformer] {
                return ["good": ReflectableTransformer(reflector: Reflector())]
            }
        }
        
        let proto: Reflectable.Type = Problematic.self
        XCTAssert(proto.ignoredProperties == ["good"])
        XCTAssert(proto.ignoreErrorsForProperties == ["good"])
        XCTAssert(proto.mappedProperties == ["good": "good"])
        let instance = proto.init()
        let property = Property(type: .string, name: "bad", required: true, mappedTo: "bad", transformer: nil)
        try! instance.set(value: "bad", for: property)
        XCTAssert(try! instance.value(for: property) as? String == "good")
        XCTAssert(proto.init().validate() == "good")
    }
    
    func testNoProperties() {
        class Object1: Reflection {
        }
        
        let object = Object1()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.isEmpty, "Reflection shouldn't have any serializable properties.")
        } catch {
            XCTFail("Reading list of properties on empty Reflection should not fail. Failed with error: \(error)")
        }
    }
}
