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

class RLObjectReflectorTests: XCTestCase {
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
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.unsupportedBaseClass(let type) {
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
            
            static let ignoredProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.cannotIgnoreNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
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
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.cannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapAndIgnoreProperty() {
        class Object1: NSObject, RLObjectProtocol {
            var someProperty = false
            
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["someProperty": "someProperty"]
            static let ignoredProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.cannotMapAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
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
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.cannotMapNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_MappedPropertyConflict() {
        class Object1: NSObject, RLObjectProtocol {
            var test1 = ""
            var test2: [Any] = []
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
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.mappedPropertyConflict(properties: let properties, conflictKey: let conflict, forClass: let classType) {
            XCTAssert(Set(properties) == Set(["test1", "test2"]))
            XCTAssert(conflict == "conflict_test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_UnsupportedPropertyValueType() {
        class Object1: NSObject, RLObjectProtocol {
            var test = Data()
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.unsupportedPropertyValueType(property: let property, valueType: let valueType, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(valueType is Data.Type)
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
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.optionalPrimitiveNumberNotBridgable(property: let property, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_PropertyNotBridgable() {
        class Object1: NSObject, RLObjectProtocol {
            @nonobjc var test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.propertyNotBridgable(property: let property, valueType: let valueType, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(valueType == Bool.self)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_ReadOnlyProperty() {
        class Object1: NSObject, RLObjectProtocol {
            let test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try RLObjectReflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch RLObjectReflectionError.readOnlyProperty(property: let property, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testNoProperties() {
        class Object1: NSObject, RLObjectProtocol {
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            let properties = try object.properties()
            XCTAssert(properties.isEmpty)
        } catch {
            XCTFail("Reading list of properties on empty class should not fail. Failed with error: \(error)")
        }
    }
}
