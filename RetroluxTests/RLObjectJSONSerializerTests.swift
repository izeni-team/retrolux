//
//  RLObjectJSONSerializerTests.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import XCTest
@testable import Retrolux

func toJSONData(_ value: Any) -> Data {
    return try! JSONSerialization.data(withJSONObject: value, options: [])
}

class RLObjectJSONSerializerTests: XCTestCase {
    func testBasicSerialization() {
        class Car: RLObject {
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
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        
        do {
            let car: Car = try serializer.serialize(from: response)
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
        class Car: RLObject {
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
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Car.self))
        
        do {
            _ = try serializer.serialize(from: response) as Car
            XCTFail("Should not have passed.")
        } catch RLObjectError.typeMismatch(expected: let expected, got: let got, property: let property, forClass: let `class`) {
            XCTAssert(expected == .string)
            
            // TODO: Can't check if 'got' is a String.Type.
            
            XCTAssert(property == "model")
            XCTAssert(`class` == Car.self)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
    
    func testArrayRoot() {
        class Car: RLObject {
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
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: [Car].self))
        
        do {
            let cars: [Car] = try serializer.serialize(from: response)
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
    
    func testNoResponse() {
        class Dummy: RLObject {}
        
        let response = ClientResponse(data: nil, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Dummy.self))
        do {
            _ = try serializer.serialize(from: response) as Dummy
            XCTFail("Should not have passed.")
        } catch RLObjectJSONSerializerError.noData {
            // Success!
        } catch {
            XCTFail("Failed with exception: \(error)")
        }
    }
    
    func testHTMLResponse() {
        class Dummy: RLObject {}
        
        let response = ClientResponse(data: "<html></html>".data(using: .utf8), response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Dummy.self))
        do {
            _ = try serializer.serialize(from: response) as Dummy
            XCTFail("Should not pass.")
        } catch RLObjectJSONSerializerError.invalidJSON {
            // Success!
        } catch {
            XCTFail("Failed with exception: \(error)")
        }
    }
    
    func testIgnoringResponseAndError() {
        class Test: RLObject {
            var pass = false
        }
        
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.google.com/")!, statusCode: 400, httpVersion: "1.1", headerFields: [:])
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [:])
        let response = ClientResponse(data: "{\"pass\": true}".data(using: .utf8), response: httpResponse, error: error)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Test.self))
        do {
            let test = try serializer.serialize(from: response) as Test
            XCTAssert(test.pass)
        } catch {
            XCTFail("Failed with exception: \(error)")
        }
    }
    
    func testArrayOfNestedObjects() {
        class Person: RLObject {
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
        
        let data = toJSONData(dictionary)
        let response = ClientResponse(data: data, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Person.self))
        do {
            let bob = try serializer.serialize(from: response) as Person
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
        class Person: RLObject {
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
        let response = ClientResponse(data: data, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Person.self))
        do {
            let bob = try serializer.serialize(from: response) as Person
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
        class Person: RLObject {
            var person_name = ""
            var pet: Pet?
        }
        
        class Pet: NSObject, RLObjectProtocol {
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
        let response = ClientResponse(data: data, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Person.self))
        do {
            let bobby = try serializer.serialize(from: response) as Person
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
        class Car: RLObject {
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
        
        let response = ClientResponse(data: responseData, response: nil, error: nil)
        
        let serializer = RLObjectJSONSerializer()
        XCTAssert(serializer.supports(type: Car.self))
        
        do {
            _ = try serializer.serialize(from: response) as Car
            XCTFail("Should not have passed.")
        } catch RLObjectError.typeMismatch(expected: let expected, got: let got, property: let property, forClass: let `class`) {
            XCTAssert(expected == .number)
            
            // TODO: Cannot check got type.
            
            XCTAssert(property == "year")
            XCTAssert(`class` == Car.self)
        } catch {
            print("Error serializing data into a basic Car: \(error)")
            XCTFail()
        }
    }
}
