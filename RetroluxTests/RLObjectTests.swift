//
//  RLObjectTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class RLObjectTests: XCTestCase {
    func testRLObjectProperties() {
        class Model: RLObject {
            dynamic var name = ""
            dynamic var yolo = false
        }
        
        do {
            let properties = try Model().properties()
            let properties2 = try RLObjectReflector().reflect(Model())
            let properties3 = try Model().properties() // Just in case caching is miserably broken
            XCTAssert(Set(properties) == Set(properties2) && Set(properties2) == Set(properties3))
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func setPropertiesHelper(_ properties: [Property], dictionary: [String: Any], instance: RLObjectProtocol) {
        XCTAssert(Set(properties.map({ $0.name })) == Set(dictionary.keys))
        
        for property in properties {
            do {
                print("BEFORE")
                try instance.set(value: dictionary[property.name], for: property)
                print("AFTER")
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        for property in properties {
            print(property.mappedTo)
            let isNSNull = dictionary[property.mappedTo] is NSNull
            let screened: NSObject? = isNSNull ? nil : dictionary[property.mappedTo] as? NSObject
            XCTAssert(instance.value(for: property) as? NSObject == screened || !property.required)
        }
    }
    
    func testRLObjectBasicSerialization() {
        class Model: RLObject {
            dynamic var name = ""
            dynamic var age = 0
            dynamic var whatever = false
            dynamic var meta = [String: String]()
            dynamic var model: Model?
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
            let properties = try model.properties()
            setPropertiesHelper(properties, dictionary: dictionary, instance: model)
        }
        catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectIgnoredProperties() {
        class Object: RLObject {
            dynamic var name = ""
            dynamic var age = 0
            
            override class var ignoredProperties: [String] {
                return ["name"]
            }
        }
        
        do {
            let properties = try RLObjectReflector().reflect(Object())
            XCTAssert(Set(properties.map({ $0.name })) == Set(["age"]))
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectIgnoredErrorsForProperties() {
        class Object: RLObject {
            dynamic var name = "default_value"
            dynamic var age = 0
            
            override class var ignoreErrorsForProperties: [String] {
                return ["name"]
            }
        }
        
        do {
            let object = Object()
            let properties = try object.properties()
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
        class Object: RLObject {
            dynamic var description_ = ""
            
            override class var mappedProperties: [String: String] {
                return ["description_": "description"]
            }
        }
        
        do {
            let properties = try RLObjectReflector().reflect(Object())
            let prop = properties.first
            XCTAssert(properties.count == 1 && prop?.mappedTo == "description" && prop?.name == "description_")
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    /*
     Tests that inheritance is properly supported when the base class is RLObject.
     */
    func testRLObjectInheritance() {
        class Plain: RLObject {
            dynamic var bad = ""
            
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "bad", forProperty: property)
            }
            
            override func value(for property: Property) -> Any? {
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
        }
        
        class Problematic: Plain {
            override func set(value: Any?, forProperty property: Property) throws {
                try super.set(value: "good", forProperty: property)
            }
            
            override func value(for property: Property) -> Any? {
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
        }
        
        let proto: RLObjectProtocol.Type = Problematic.self
        XCTAssert(proto.ignoredProperties == ["good"])
        XCTAssert(proto.ignoreErrorsForProperties == ["good"])
        XCTAssert(proto.mappedProperties == ["good": "good"])
        let instance = proto.init()
        let property = Property(type: .string, name: "bad", required: true, mappedTo: "bad", transformer: nil)
        try! instance.set(value: "bad", for: property)
        XCTAssert(instance.value(for: property) as? String == "good")
        XCTAssert(proto.init().validate() == "good")
    }
    
    func testNoProperties() {
        class Object1: RLObject {
        }
        
        let object = Object1()
        do {
            let properties = try object.properties()
            XCTAssert(properties.isEmpty, "RLObject shouldn't have any serializable properties.")
        } catch {
            XCTFail("Reading list of properties on empty RLObject should not fail. Failed with error: \(error)")
        }
    }
}
