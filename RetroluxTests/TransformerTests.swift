//
//  TransformerTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux
import XCTest

class TransformerTests: XCTestCase {
    func testBasicTransformer() {
        class BasicTransformer: NestedTransformer {
            static let shared = BasicTransformer()
            
            typealias TypeOfProperty = Data
            typealias TypeOfData = String
            
            func setter(_ dataValue: String, type: Any.Type) throws -> Data {
                return dataValue.data(using: .utf8)!
            }
            
            func getter(_ propertyValue: Data) throws -> String {
                return String(data: propertyValue, encoding: .utf8)!
            }
        }
        
        class Person: NSObject, Reflectable {
            @objc var data = Data()
            
            static func config(_ c: PropertyConfig) {
                c["data"] = [.transformed(BasicTransformer.shared)]
            }
            
            required override init() {
                super.init()
            }
        }
        
        do {
            let reflector = Reflector()
            let person = Person()
            let properties = try reflector.reflect(person)
            XCTAssert(properties.count == 1)
            XCTAssert(properties.first?.name == "data")
            XCTAssert(properties.first?.type == .unknown(Data.self))
            XCTAssert(properties.first?.transformer === BasicTransformer.shared)
            XCTAssert(properties.first?.ignored == false)
            XCTAssert(properties.first?.nullable == false)
            XCTAssert(properties.first?.options.count == 1)
            if let option = properties.first?.options.first, case .transformed(let transformer) = option {
                XCTAssert(transformer === BasicTransformer.shared)
            } else {
                XCTFail("Wrong customization options on property.")
            }
            XCTAssert(properties.first?.serializedName == "data")
            XCTAssert(properties.first?.type == .unknown(Data.self))
            
            try reflector.set(value: "123", for: properties.first!, on: person)
            XCTAssert(person.data == "123".data(using: .utf8)!)
            let value = try reflector.value(for: properties.first!, on: person)
            XCTAssert(value as? String == "123")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    // This test cannot be run multiple times without recycling state.
    func testLocalTransformerOverridesGlobalTransformer() {
        class Transformer: ReflectableTransformer {
            var wasCalled = false
            
            static let reflector = Reflector()
            static let global = Transformer(weakReflector: reflector)
            static let local = Transformer(weakReflector: reflector)
            
            override func setter(_ dataValue: ReflectableTransformer.TypeOfData, type: Any.Type) throws -> ReflectableTransformer.TypeOfProperty {
                wasCalled = true
                return try super.setter(dataValue, type: type)
            }
        }
        
        class Person: Reflection {
            @objc var custom: Person?
            
            static var useLocalTransformer = true
            
            override class func config(_ c: PropertyConfig) {
                if useLocalTransformer {
                    c["custom"] = [.transformed(Transformer.local)]
                }
            }
        }
        
        Transformer.reflector.globalTransformers = [Transformer.global]
        
        let data = "{\"custom\": {}}".data(using: .utf8)!
        do {
            _ = try Transformer.reflector.convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(Transformer.global.wasCalled == false)
            XCTAssert(Transformer.local.wasCalled == true)
            
            // Clear state
            Transformer.local.wasCalled = false
            Transformer.global.wasCalled = false
            Transformer.reflector.cache.removeAll()
            
            // Disable local transformer
            Person.useLocalTransformer = false
            
            _ = try Transformer.reflector.convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(Transformer.global.wasCalled == true)
            XCTAssert(Transformer.local.wasCalled == false)
        } catch {
            XCTFail("Should have succeeded, but got error: \(error)")
        }
    }
    
    func testURLTransformer() {
        class Person: Reflection {
            @objc var image_url: URL?
        }
        
        // The escaped forwards slash is intentional, and is just NSJSONSerialization trying to conform to HTML
        // standards:
        // https://stackoverflow.com/questions/19651009/how-to-prevent-nsjsonserialization-from-adding-extra-escapes-in-url
        let data = "{\"image_url\":\"https:\\/\\/www.google.com\\/somepath%20with%20spaces\"}".data(using: .utf8)!
        let image_url = URL(string: "https://www.google.com/somepath%20with%20spaces")!
        do {
            let person = try Reflector().convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(person.image_url == URL(string: "https://www.google.com/somepath%20with%20spaces")!)
            XCTAssert(person.image_url == image_url)
            XCTAssert(person.image_url?.scheme == "https")
            XCTAssert(person.image_url?.host == "www.google.com")
            XCTAssert(person.image_url?.path == "/somepath with spaces")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let person = Person()
            person.image_url = image_url
            let out = try Reflector().convertToJSONDictionaryData(from: person)
            XCTAssert(out == data)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let nullData = "{\"image_url\":null}".data(using: .utf8)!
            let person = try Reflector().convert(fromJSONDictionaryData: nullData, to: Person.self) as! Person
            XCTAssert(person.image_url == nil)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let boringStringData = "{\"image_url\":\"boring\"}".data(using: .utf8)!
            let person = try Reflector().convert(fromJSONDictionaryData: boringStringData, to: Person.self) as! Person
            XCTAssert(person.image_url == URL(string: "boring")!)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let invalidUrlData = "{\"image_url\":\"a string with spaces\"}".data(using: .utf8)!
            _ = try Reflector().convert(fromJSONDictionaryData: invalidUrlData, to: Person.self) as! Person
            XCTFail("Should not have succeeded.")
        } catch {
            if case URLTransformer.Error.invalidURL = error {
                /* SUCCESS */
            } else {
                XCTFail("Expected an invalidURL error, but got the following instead: \(error)")
            }
        }
        
        do {
            let invalidUrlData = "{\"image_url\":\"|\"}".data(using: .utf8)!
            _ = try Reflector().convert(fromJSONDictionaryData: invalidUrlData, to: Person.self) as! Person
            XCTFail("Should not have succeeded.")
        } catch {
            if case URLTransformer.Error.invalidURL = error {
                /* SUCCESS */
            } else {
                XCTFail("Expected an invalidURL error, but got the following instead: \(error)")
            }
        }
    }
}
