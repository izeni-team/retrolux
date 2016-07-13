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

extension RetroluxTests {
    func setPropertiesHelper(properties: [Property], dictionary: [String: AnyObject], instance: RLObjectProtocol) {
        XCTAssert(Set(properties.map({ $0.name })) == Set(dictionary.keys))
        
        for property in properties {
            do {
                try instance.set(value: dictionary[property.name], forProperty: property)
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        for property in properties {
            print(property.mappedTo)
            let isNSNull = dictionary[property.mappedTo] is NSNull
            let screened: NSObject? = isNSNull ? nil : dictionary[property.mappedTo] as? NSObject
            XCTAssert(instance.valueFor(property) as? NSObject == screened || !property.required)
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
        
        var dictionary = [
            "name": "Bryan",
            "age": 23,
            "whatever": true,
            "meta": [
                "place_of_birth": "Bluffdale, UT",
                "height": "5' 7\""
            ],
            "model": NSNull()
        ]
        
        do {
            let model = Model()
            let properties = try RLObjectReflector().reflect(model)
            setPropertiesHelper(properties, dictionary: dictionary, instance: model)
            XCTAssert(model.name == dictionary["name"])
            XCTAssert(model.age == dictionary["age"])
            XCTAssert(model.meta == dictionary["meta"])
            XCTAssert(model.whatever == dictionary["whatever"])
            XCTAssert(model.model == nil && dictionary["model"] == NSNull())
        }
        catch let error {
            XCTFail("\(error)")
        }
    }
    
    // TODO: Test ignored, ignored errors, and mapped.
    
    /*
     Tests that inheritance is properly supported when the base class is RLObject.
     */
    func testRLObjectInheritance() {
        class Plain: RLObject {
            dynamic var bad = ""
            
            override func set(value value: Any?, forProperty property: Property) throws {
                // TODO: Avoid duplication?
                try super.set(value: "bad", forProperty: property)
            }
            
            override func valueFor(property: Property) -> Any? {
                // TODO: Avoid duplication?
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
            override func set(value value: Any?, forProperty property: Property) throws {
                // TODO: Avoid duplication?
                try super.set(value: "good", forProperty: property)
            }
            
            override func valueFor(property: Property) -> Any? {
                // TODO: Avoid duplication?
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
        let property = Property(type: .string, name: "bad", required: true, mappedTo: "bad")
        try! instance.set(value: "bad", forProperty: property)
        XCTAssert(instance.valueFor(property) as? String == "good")
        XCTAssert(proto.init().validate() == "good")
    }
}