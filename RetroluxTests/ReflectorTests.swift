//
//  RetroluxReflectorTests.swift
//  RetroluxReflectorTests
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import Retrolux

func toJSONData(_ object: Any) -> Data {
    return try! JSONSerialization.data(withJSONObject: object, options: [])
}

class RetroluxReflectorTests: XCTestCase {
    func testSetProperty() {
        class Test: Reflection {
            var name = ""
            var nested: Test?
        }
        
        do {
            let test = Test()
            let properties = try Reflector().reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == PropertyType.optional(wrapped: .transformable(transformer: ReflectableTransformer(reflector: Reflector()), targetType: Test.self)))
            try test.set(value: ["name": "success"], forProperty: properties.last!)
            XCTAssert(test.nested?.name == "success")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNestedInDictionary() {
        class Test: Reflection {
            var name = ""
            var nested: [String: Test] = [:]
        }
        
        let nestedDictionary: [String: Any] = [
            "bob": [
                "name": "Bob",
                "nested": [:]
            ],
            "alice": [
                "name": "Alice",
                "nested": [:]
            ]
        ]
        
        do {
            let test = Test()
            let properties = try Reflector().reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.count == 2)
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == PropertyType.dictionary(type: PropertyType.transformable(transformer: ReflectableTransformer(reflector: Reflector()), targetType: Test.self)))
            try test.set(value: nestedDictionary, for: properties.last!)
            XCTAssert(test.nested["bob"]?.name == "Bob")
            XCTAssert(test.nested["alice"]?.name == "Alice")
            XCTAssert(test.nested.count == 2)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNestedArrayAndDictionary() {
        class Test: Reflection {
            var name = ""
            var nested: [[String: Test]] = []
        }
        
        let nestedArray: [[String: Any]] = [
            [
                "bob": [
                    "name": "Bob",
                    "nested": []
                ],
                "alice": [
                    "name": "Alice",
                    "nested": []
                ]
            ],
            [
                "robert": [
                    "name": "Robert",
                    "nested": []
                ],
                "alicia": [
                    "name": "Alicia",
                    "nested": []
                ]
            ],
            ]
        
        do {
            let test = Test()
            let properties = try Reflector().reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.count == 2)
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == PropertyType.array(type: PropertyType.dictionary(type: PropertyType.transformable(transformer: ReflectableTransformer(reflector: Reflector()), targetType: Test.self))))
            try test.set(value: nestedArray, for: properties.last!)
            XCTAssert(test.nested.count == 2)
            XCTAssert(test.nested[0]["bob"]?.name == "Bob")
            XCTAssert(test.nested[0]["alice"]?.name == "Alice")
            XCTAssert(test.nested[1]["robert"]?.name == "Robert")
            XCTAssert(test.nested[1]["alicia"]?.name == "Alicia")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testBasicSerialization() {
        class Car: Reflection {
            var make = ""
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let responseData = toJSONData([
            "make": "Honda",
            "model": "Civic",
            "year": 1988,
            "dealership": true
            ])
        
        let reflector = Reflector()
        
        do {
            let car = try reflector.convert(fromJSONDictionaryData: responseData, to: Car.self) as! Car
            XCTAssert(car.make == "Honda")
            XCTAssert(car.model == "Civic")
            XCTAssert(car.year == 1988)
            XCTAssert(car.dealership == true)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
    
    func testNullableSerialization() {
        class Car: Reflection {
            var make: String? = "wrong"
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let responseData = toJSONData([
            "make": NSNull(),
            "model": NSNull(),
            "year": 1988,
            "dealership": true
            ])
        
        let reflector = Reflector()
        
        do {
            _ = try reflector.convert(fromJSONDictionaryData: responseData, to: Car.self)
            XCTFail("Should not have passed.")
        } catch ReflectorSerializationError.propertyDoesNotSupportNullValues(propertyName: let propertyName, forClass: let `class`) {
            XCTAssert(propertyName == "model")
            XCTAssert(`class` == Car.self)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testArrayRoot() {
        class Car: Reflection {
            var make = ""
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let carData1: [String: Any] = [
            "make": "Honda",
            "model": "Civic",
            "year": 1988,
            "dealership": true
        ]
        let carData2: [String: Any] = [
            "make": "Ford",
            "model": "Escape",
            "year": 2001,
            "dealership": false
        ]
        let responseData = toJSONData([carData1, carData2])
        
        let reflector = Reflector()
        
        do {
            let cars = try reflector.convert(fromJSONArrayData: responseData, to: Car.self) as! [Car]
            XCTAssert(cars.count == 2)
            
            let first = cars.first
            XCTAssert(first?.make == "Honda")
            XCTAssert(first?.model == "Civic")
            XCTAssert(first?.year == 1988)
            XCTAssert(first?.dealership == true)
            
            let last = cars.last
            XCTAssert(last?.make == "Ford")
            XCTAssert(last?.model == "Escape")
            XCTAssert(last?.year == 2001)
            XCTAssert(last?.dealership == false)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
    
    func testHTMLResponse() {
        class Dummy: Reflection {}
        
        let responseData = "<html></html>".data(using: .utf8)!
        
        let reflector = Reflector()

        do {
            _ = try reflector.convert(fromJSONDictionaryData: responseData, to: Dummy.self)
            XCTFail("Should not pass.")
        } catch ReflectorSerializationError.invalidJSONData(_) {
            // SUCCESS!
        } catch {
            XCTFail("Failed with exception: \(error)")
        }
    }
    
    func testArrayOfNestedObjects() {
        class Person: Reflection {
            var name = ""
            var friends: [Person] = []
        }
        
        let dictionary: [String: Any] = [
            "name": "Bob",
            "friends": [
                [
                    "name": "Alice",
                    "friends": []
                ],
                [
                    "name": "Charles",
                    "friends": [
                        [
                            "name": "Drew",
                            "friends": []
                        ]
                    ]
                ]
            ]
        ]
        
        let reflector = Reflector()

        do {
            let bob = try reflector.convert(fromDictionary: dictionary, to: Person.self) as! Person
            XCTAssert(bob.name == "Bob")
            XCTAssert(bob.friends.count == 2)
            
            let first = bob.friends.first
            XCTAssert(first?.name == "Alice")
            XCTAssert(first?.friends.count == 0)
            
            let last = bob.friends.last
            XCTAssert(last?.name == "Charles")
            XCTAssert(last?.friends.count == 1)
            
            let charlesFriend = last?.friends.first
            XCTAssert(charlesFriend?.name == "Drew")
            XCTAssert(charlesFriend?.friends.count == 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testDictionaryOfNestedObjects() {
        class Person: Reflection {
            var name = ""
            var friends: [String: [String: Person]] = [:]
        }
        
        let dictionary: [String: Any] = [
            "name": "Bob",
            "friends": [
                "layer_1": [
                    "layer_2": [
                        "name": "Alice",
                        "friends": [:]
                    ]
                ]
            ]
        ]
        
        let data = toJSONData(dictionary)
        
        let reflector = Reflector()

        do {
            let bob = try reflector.convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(bob.name == "Bob")
            XCTAssert(bob.friends.count == 1)
            
            guard let layer_1 = bob.friends["layer_1"] else {
                XCTFail("Failed to find layer_1")
                return
            }
            
            guard let layer_2 = layer_1["layer_2"] else {
                XCTFail("Failed to find layer_2")
                return
            }
            
            XCTAssert(layer_2.name == "Alice")
            XCTAssert(layer_2.friends.isEmpty)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testSingleNestedObject() {
        class Person: Reflection {
            var person_name = ""
            var pet: Pet?
        }
        
        class Pet: NSObject, Reflectable {
            var pet_name = ""
            
            required override init() {
                super.init()
            }
        }
        
        let dictionary: [String: Any] = [
            "person_name": "Bobby",
            "pet": [
                "pet_name": "Fluffy"
            ]
        ]
        
        let data = toJSONData(dictionary)
        
        let reflector = Reflector()

        do {
            let bobby = try reflector.convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(bobby.person_name == "Bobby")
            
            guard let pet = bobby.pet else {
                XCTFail("Failed to find pet on person.")
                return
            }
            
            XCTAssert(pet.pet_name == "Fluffy")
        } catch {
            XCTFail("Failed with exception: \(error)")
        }
    }
    
    func testMismatchedJSON() {
        class Car: Reflection {
            var make = ""
            var model = ""
            var year = 0
            var dealership = false
        }
        
        let responseData = toJSONData([
            "make": "Honda",
            "model": "Civic",
            "year": "1988", // Class expects an integer, so this should trigger an error.
            "dealership": true
            ])
        
        let reflector = Reflector()
        
        do {
            _ = try reflector.convert(fromJSONDictionaryData: responseData, to: Car.self)
            XCTFail("Should not have passed.")
        } catch ReflectorSerializationError.typeMismatch(expected: let expected, got: let got, propertyName: let propertyName, forClass: let `class`) {
            XCTAssert(expected == .number(exactType: Int.self))
            
            // TODO: Cannot check got type. It's always Optional<Optional<Any>> it seems... :-(
            
            XCTAssert(propertyName == "year")
            XCTAssert(`class` == Car.self)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
    
    func testSendBasicObject() {
        class Object: Reflection {
            var name = ""
            var age = 0
        }
        
        let object = Object()
        object.name = "Bryan"
        object.age = 24
        
        let reflector = Reflector()
        
        do {
            let data = try reflector.convertToJSONDictionaryData(from: object)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                XCTFail("Serializer set incorrect root type. Expected dictionary.")
                return
            }
            XCTAssert(dictionary["name"] as? String == "Bryan")
            XCTAssert(dictionary["age"] as? Int == 24)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testSendAndReceiveComplexObject() {
        class Pet: Reflection {
            var name = ""
            
            convenience init(name: String) {
                self.init()
                self.name = name
            }
        }
        
        class Person: Reflection {
            var name = ""
            var age = 0
            var born = Date()
            var visitDates: [Date] = []
            var pets: [Pet] = []
            var bestFriend: Person?
            var upgradedAt: Date?
            
            override class var transformedProperties: [String: Retrolux.ValueTransformer] {
                return [
                    "born": DateTransformer.shared,
                    "visitDates": DateTransformer.shared,
                    "upgradedAt": DateTransformer.shared
                ]
            }
            
            override class var mappedProperties: [String: String] {
                return [
                    "visitDates": "visit_dates",
                    "bestFriend": "best_friend",
                    "upgradedAt": "upgraded_at"
                ]
            }
        }
        
        let object = Person()
        object.name = "Bryan"
        object.age = 24
        object.born = Date(timeIntervalSince1970: -86400 * 365 * 24) // Roughly 24 years ago.
        
        let now = Date()
        let date2 = Date(timeIntervalSince1970: 276246)
        let date3 = Date(timeIntervalSinceReferenceDate: 123873)
        object.visitDates = [
            now,
            date2,
            date3
        ]
        
        object.pets = [
            Pet(name: "Fifi"),
            Pet(name: "Tiger")
        ]
        
        let bestFriend = Person()
        bestFriend.name = "Bob"
        bestFriend.age = 2
        bestFriend.born = Date(timeIntervalSinceNow: -86400 * 365 * 2)
        bestFriend.upgradedAt = now
        object.bestFriend = bestFriend
        
        let reflector = Reflector()
        
        do {
            let data = try reflector.convertToJSONDictionaryData(from: object)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                XCTFail("Serializer set incorrect root type. Expected dictionary.")
                return
            }
            XCTAssert(dictionary["name"] as? String == "Bryan")
            XCTAssert(dictionary["age"] as? Int == 24)
            
            let dates = dictionary["visit_dates"] as? [String]
            XCTAssert(dates?.count == 3)
            let transformer = DateTransformer()
            XCTAssert(dates?[0] == transformer.formatter.string(from: now))
            XCTAssert(dates?[1] == transformer.formatter.string(from: date2))
            XCTAssert(dates?[2] == transformer.formatter.string(from: date3))
            
            let pets = dictionary["pets"] as? [[String: Any]]
            XCTAssert(pets?.count == 2)
            XCTAssert(pets?[0]["name"] as? String == "Fifi")
            XCTAssert(pets?[1]["name"] as? String == "Tiger")
            
            let bf = dictionary["best_friend"] as? [String: Any]
            XCTAssert(bf?["name"] as? String == "Bob")
            XCTAssert(bf?["age"] as? Int == 2)
            XCTAssert(bf?["born"] as? String == transformer.formatter.string(from: bestFriend.born))
            XCTAssert(bf?["upgraded_at"] as? String == transformer.formatter.string(from: bestFriend.upgradedAt!))
            
            XCTAssert(dictionary["upgraded_at"] is NSNull)

            let serialized = try reflector.convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            XCTAssert(serialized.name == object.name)
            XCTAssert(serialized.age == object.age)
            XCTAssert(serialized.born.toString() == object.born.toString())
            XCTAssert(serialized.visitDates.map { $0.toString() } == object.visitDates.map { $0.toString() })
            XCTAssert(serialized.pets.map { $0.name } == object.pets.map { $0.name })
            XCTAssert(serialized.bestFriend?.name == object.bestFriend?.name)
            XCTAssert(serialized.bestFriend?.age == object.bestFriend?.age)
            XCTAssert(serialized.bestFriend?.upgradedAt?.toString() == object.bestFriend?.upgradedAt?.toString())
            XCTAssert(serialized.upgradedAt == nil && object.upgradedAt == nil)
            XCTAssert(serialized.bestFriend?.bestFriend == nil)
            XCTAssert(serialized.bestFriend?.visitDates.isEmpty == true)
            XCTAssert(serialized.bestFriend?.born.toString() == object.bestFriend?.born.toString())
            XCTAssert(serialized.bestFriend?.pets.isEmpty == true)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testAlternativeInheritance() {
        class Test: CustomObject {
            var name = ""
        }
        let t = Test()
        do {
            let properties = try Reflector.shared.reflect(t)
            XCTAssert(properties.count == 1 && properties.first?.name == "name")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}

class Object: NSObject {
}
class CustomObject: Object {
    required override init() {
        super.init()
    }
}
extension CustomObject: ReflectableSubclassingIsAllowed {}
extension CustomObject: Reflectable {}

extension Date {
    fileprivate func toString() -> String {
        return DateTransformer.shared.formatter.string(from: self)
    }
}
