//
//  ReflectionErrorTests.swift
//  RetroluxReflector
//
//  Created by Christopher Bryan Henderson on 10/17/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import Retrolux

protocol TestProtocol {
    var instanceTest: Bool { get }
    static var test: Bool { get }
    static func testFunc() -> Bool
}

extension TestProtocol {
    var instanceTest: Bool {
        return false
    }
    static var test: Bool {
        return false
    }
    static func testFunc() -> Bool {
        return false
    }
}

class ReflectionErrorTests: XCTestCase {
    func helper<T: TestProtocol>(t: T) -> Bool {
        return t.instanceTest
    }
    
    // This test checks Swift protocol inheritance behavior for protocols.
    func testSwiftProtocolLimitations() {
        class ImproperBase: TestProtocol {
            
        }
        
        class ImproperChild: ImproperBase {
            var instanceTest: Bool {
                return true
            }
            
            static var test: Bool {
                return true
            }
            
            static func testFunc() -> Bool {
                return true
            }
        }
        
        let improper = ImproperChild()
        XCTAssert(improper.instanceTest == true)
        XCTAssert((improper as TestProtocol).instanceTest == false)
        XCTAssert(helper(t: improper) == false)
        
        let improperProto: TestProtocol.Type = type(of: ImproperChild())
        XCTAssert(improperProto.test == false)
        XCTAssert(improperProto.testFunc() == false)
        
        /// This is the way inheritance should be to work properly. ///
        
        class ProperBase: TestProtocol {
            class var test: Bool {
                return false
            }
            
            class func testFunc() -> Bool {
                return false
            }
        }
        
        class ProperChild: ProperBase {
            override class var test: Bool {
                return true
            }
            
            override class func testFunc() -> Bool {
                return true
            }
        }
        
        let properProto: TestProtocol.Type = type(of: ProperChild())
        XCTAssert(properProto.test == true)
        XCTAssert(properProto.testFunc() == true)
    }
    
    func testRLObjectReflection_customBaseClass() {
        class Object1: NSObject, Reflectable, ReflectableSubclassingIsAllowed {
            required override init() {
                super.init()
            }
        }
        
        class Object2: Object1 {}
        
        // Inheriting Object1 should succeed.
        do {
            _ = try Reflector().reflect(Object2())
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        class Object3: NSObject, Reflectable {
            required override init() {
                super.init()
            }
        }
        
        class Object4: Object3 {}
        
        // Inheriting Object3 should fail.
        do {
            _ = try Reflector().reflect(Object4())
            XCTFail("Should not have succeeded.")
        } catch ReflectionError.subclassingNotAllowed(let type) {
            XCTAssert(type == Object3.self)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    // Disabled, because this behavior prevents custom base classes + inheritance.
    func testRLObjectReflectorError_UnsupportedBaseClass() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
        }
        
        class Object2: Object1 {}
        
        // Inheriting object 1 should fail
        do {
            _ = try Reflector().reflect(Object2())
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.subclassingNotAllowed(let type) {
            // TODO: Return enum values instead of strings
            XCTAssert(type == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testReflectionInheritance() {
        // Inheriting from Reflection should succeed
        class Object3: Reflection {}
        class Object4: Object3 {}
        do {
            _ = try Reflector().reflect(Object4())
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let ignoredProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotIgnoreNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreErrorsForNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let ignoreErrorsForProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapAndIgnoreProperty() {
        class Object1: NSObject, Reflectable {
            var someProperty = false
            
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["someProperty": "someProperty"]
            static let ignoredProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotMapAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "someProperty")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotTransformAndIgnoreProperty() {
        struct DummyTransformer: Retrolux.ValueTransformer {
            func supports(targetType: Any.Type) -> Bool {
                return true
            }
            func supports(value: Any, targetType: Any.Type, direction: ValueTransformerDirection) -> Bool {
                return true
            }
            
            func transform(_ value: Any, targetType: Any.Type, direction: ValueTransformerDirection) throws -> Any {
                return value
            }
        }
        
        class Object1: NSObject, Reflectable {
            var someProperty = false
            
            required override init() {
                super.init()
            }
            
            // TODO: The type has to be explicitly set because DummyTransformer.self != ValueTransformer.Type
            static let transformedProperties: [String: Retrolux.ValueTransformer] = ["someProperty": DummyTransformer()]
            static let ignoredProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotTransformAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "someProperty")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["does_not_exist": "something_else"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotMapNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotTransformNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let transformedProperties: [String: Retrolux.ValueTransformer] = ["does_not_exist": ReflectableTransformer(reflector: Reflector())]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotTransformNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_MappedPropertyConflict() {
        class Object1: NSObject, Reflectable {
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
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.mappedPropertyConflict(properties: let properties, conflictKey: let conflict, forClass: let classType) {
            XCTAssert(Set(properties) == Set(["test1", "test2"]))
            XCTAssert(conflict == "conflict_test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_UnsupportedPropertyValueType() {
        class Object1: NSObject, Reflectable {
            var test = Data()
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.propertyNotSupported(propertyName: let propertyName, valueType: let valueType, forClass: let classType) {
            XCTAssert(propertyName == "test")
            XCTAssert(valueType is Data.Type)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_OptionalPrimitiveNumberNotBridgable() {
        class Object1: NSObject, Reflectable {
            var test: Int? = nil
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.optionalNumericTypesAreNotSupported(propertyName: let propertyName, unwrappedType: let unwrappedType, forClass: let classType) {
            XCTAssert(propertyName == "test")
            XCTAssert(unwrappedType == Int.self)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_PropertyNotBridgable() {
        class Object1: NSObject, Reflectable {
            @nonobjc var test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.propertyNotSupported(propertyName: let propertyName, valueType: let valueType, forClass: let classType) {
            XCTAssert(propertyName == "test")
            XCTAssert(valueType == Bool.self)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflection_ReadOnlyProperty() {
        class Object1: NSObject, Reflectable {
            let test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.isEmpty)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_ReadOnlyProperty() {
        class Object1: NSObject, Reflectable {
            let test = false
            
            required override init() {
                super.init()
            }
            
            static let mappedProperties: [String: String] = [
                "test": "test"
            ]
        }
        
        let object = Object1()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.isEmpty)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotMapAndIgnoreProperty(propertyName: let propertyName, forClass: let `class`) {
            XCTAssert(propertyName == "test")
            XCTAssert(`class` == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testNoProperties() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.isEmpty)
        } catch {
            XCTFail("Reading list of properties on empty class should not fail. Failed with error: \(error)")
        }
    }
    
    func testOptionalValueNotSupported() {
        class Person: Reflection {
            var name = ""
        }
        
        let object = Person()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.count == 1)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.first?.type == .string)
            try object.set(value: NSNull(), for: properties.first!)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectorSerializationError.propertyDoesNotSupportNullValues(propertyName: let propertyName, forClass: let `class`) {
            XCTAssert(propertyName == "name")
            XCTAssert(`class` == Person.self)
        } catch {
            XCTFail("\(error)")
        }
        
        let data = "{\"name\":null}".data(using: .utf8)!
        
        do {
            let reflector = Reflector()
            _ = try reflector.convert(fromJSONDictionaryData: data, to: Person.self)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectorSerializationError.propertyDoesNotSupportNullValues(propertyName: let propertyName, forClass: let `class`) {
            XCTAssert(propertyName == "name")
            XCTAssert(`class` == Person.self)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testKeyNotFound() {
        class Person: Reflection {
            var name = ""
            
            override class var mappedProperties: [String: String] {
                return [
                    "name": "not_name"
                ]
            }
        }
        
        let object = Person()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.count == 1)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.first?.type == .string)
            try object.set(value: nil, for: properties.first!)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectorSerializationError.keyNotFound(propertyName: let propertyName, key: let key, forClass: let `class`) {
            XCTAssert(propertyName == "name")
            XCTAssert(key == "not_name")
            XCTAssert(`class` == Person.self)
        } catch {
            XCTFail("\(error)")
        }
        
        let data = "{}".data(using: .utf8)!
        
        do {
            let reflector = Reflector()
            _ = try reflector.convert(fromJSONDictionaryData: data, to: Person.self)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectorSerializationError.keyNotFound(propertyName: let propertyName, key: let key, forClass: let `class`) {
            XCTAssert(propertyName == "name")
            XCTAssert(key == "not_name")
            XCTAssert(`class` == Person.self)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testInvalidRootJSONType() {
        class Person: Reflection {}
        
        do {
            _ = try Reflector().convert(fromJSONDictionaryData: "[{}]".data(using: .utf8)!, to: Person.self)
            XCTFail("Should not have succeeded.")
        } catch ReflectorSerializationError.expectedDictionaryRootButGotArrayRoot(type: let type) {
            XCTAssert(type == Person.self)
        } catch {
            XCTFail("\(error)")
        }
        
        do {
            _ = try Reflector().convert(fromJSONArrayData: "{}".data(using: .utf8)!, to: Person.self)
            XCTFail("Should not have succeeded.")
        } catch ReflectorSerializationError.expectedArrayRootButGotDictionaryRoot(type: let type) {
            XCTAssert(type == Person.self)
        } catch {
            XCTFail("\(error)")
        }
        
        do {
            _ = try Reflector().convert(fromJSONArrayData: "null".data(using: .utf8)!, to: Person.self)
            XCTFail("Should not have succeeded.")
        } catch ReflectorSerializationError.invalidJSONData(_) {
            // SUCCESS!
        } catch {
            XCTFail("\(error)")
        }
    }
}
