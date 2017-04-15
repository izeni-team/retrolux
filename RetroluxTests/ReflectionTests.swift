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
            let value = dictionary[property.serializedName] as? NSObject
            XCTAssert(try! instance.value(for: property) as? NSObject == value || property.ignored)
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
            
            override class func config(_ c: PropertyConfig) {
                c["name"] = [.ignored]
            }
        }
        
        do {
            let properties = try Reflector().reflect(Object())
            
            XCTAssert(Set(properties.map({ $0.name })) == Set(["age"]))
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectNullablePropertyConfig() {
        class Object: Reflection {
            var name = "default_value"
            var age = 0
            
            override class func config(_ c: PropertyConfig) {
                c["name"] = [.nullable]
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
            
            override class func config(_ c: PropertyConfig) {
                c["description_"] = [.serializedName("description")]
            }
        }
        
        do {
            let properties = try Reflector().reflect(Object())
            let prop = properties.first
            XCTAssert(properties.count == 1 && prop?.serializedName == "description" && prop?.name == "description_")
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
            
            required init() {
                super.init()
            }
            
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "bad", forProperty: property)
            }
            
            override func value(for property: Property) throws -> Any? {
                return "bad"
            }
            
            override func validate() throws {
                throw NSError(domain: "bad", code: 0, userInfo: [:])
            }
            
            override class func config(_ c: PropertyConfig) {
                c["bad"] = [.serializedName("bad")]
            }
        }
        
        class Problematic: Plain {
            required init() {
                super.init()
                bad = "good"
            }
            
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "good", forProperty: property)
            }
            
            override func value(for property: Property) throws -> Any? {
                return "good"
            }
            
            override func validate() throws {
                throw NSError(domain: "good", code: 0, userInfo: [:])
            }
            
            override class func config(_ c: PropertyConfig) {
                c["bad"] = [.serializedName("good")]
            }
        }
        
        let proto: Reflectable.Type = Problematic.self
        let config = PropertyConfig()
        proto.config(config)
        if let option = config["bad"].first, case .serializedName(let serializedName) = option {
            XCTAssert(serializedName == "good")
        } else {
            XCTFail("Failed to find config option.")
        }
        let instance = proto.init()
        let property = Property(type: .string, name: "bad", options: [.serializedName("bad")])
        XCTAssert(try! instance.value(for: property) as? String == "good")
        try! instance.set(value: "bad", for: property)
        XCTAssert(try! instance.value(for: property) as? String == "good")
        do {
            try proto.init().validate()
            XCTFail("Did not expect to succeed.")
        } catch let error as NSError {
            XCTAssert(error.domain == "good")
        }
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
