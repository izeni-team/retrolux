//
//  RLObjectReflectorTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

extension RetroluxTests {
    func testRLObjectReflectorError_UnsupportedBaseClass() {
        class Object1: NSObject, RLObjectProtocol {
            required override init() {
                super.init()
            }
        }
        
        class Object2: Object1 {}
        
        // Inheriting object 1 should fail
        do {
            _ = try RLObjectReflector().reflect(Object2())
        } catch RLObjectReflectionError.UnsupportedBaseClass(let type) {
            // TODO: Return enum values instead of strings
            XCTAssert(type == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
        
        // Inheriting from RLObject should succeed
        class Object3: RLObject {}
        class Object4: Object3 {}
        do {
            _ = try RLObjectReflector().reflect(Object4())
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreNonExistantProperty() {
        class Object1: NSObject, RLObjectProtocol {
            required override init() {
                super.init()
            }
            
            static let ignoreProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.CannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreErrorsForNonExistantProperty() {
        class Object1: NSObject, RLObjectProtocol {
            required override init() {
                super.init()
            }
            
            static let ignoreErrorsForProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.CannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreErrorsAndIgnoreProperty() {
        class Object1: NSObject, RLObjectProtocol {
            // Dynamic keyword is required because Swift removes dynamic dispatch for performance reasons
            dynamic var someProperty = false
            
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["someProperty"]
            static let ignoreErrorsForProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.CannotIgnoreErrorsAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(propertyName == "someProperty")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapNonExistantProperty() {
        class Object1: NSObject, RLObjectProtocol {
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["does_not_exist": "something_else"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.CannotMapNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_MappedPropertyConflict() {
        class Object1: NSObject, RLObjectProtocol {
            var test1 = ""
            var test2 = ""
            required override init() {
                super.init()
            }
            
            static let mappedProperties = [
                "test1": "conflict_test",
                "test2": "conflict_test"
            ]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.MappedPropertyConflict(properties: let properties, conflictKey: let conflict, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(Set(properties) == Set(["test1", "test2"]))
            XCTAssert(conflict == "conflict_test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_UnsupportedPropertyValueType() {
        class Object1: NSObject, RLObjectProtocol {
            var test = NSData()
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.UnsupportedPropertyValueType(property: let property, valueType: let valueType, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(property == "test")
            XCTAssert(valueType is NSData.Type) // Can't just check via == because it could be _NSZeroData or something not NSData
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_OptionalPrimitiveNumberNotBridgable() {
        class Object1: NSObject, RLObjectProtocol {
            var test: Int? = nil
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.OptionalPrimitiveNumberNotBridgable(property: let property, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_PropertyNotBridgable() {
        class Object1: NSObject, RLObjectProtocol {
            var test = false // Swift optimizes away Obj-C compatibility here without dynamic or @objc
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.PropertyNotBridgable(property: let property, valueType: let valueType, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(property == "test")
            XCTAssert(valueType == Bool.self)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_ReadOnlyProperty() {
        class Object1: NSObject, RLObjectProtocol {
            dynamic let test = "" // Without dynamic keyword, falls back to PropertyNotBridgable
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
        } catch RLObjectReflectionError.ReadOnlyProperty(property: let property, forClass: let classType) {
            // TODO: Return enum values instead of strings
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
}