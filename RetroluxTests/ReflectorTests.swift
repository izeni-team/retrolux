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
    func testScope() {
        var transformer: ReflectableTransformer!
        if (true) {
            let reflector = Reflector()
            transformer = reflector.reflectableTransformer as! ReflectableTransformer
            XCTAssert(transformer.reflector === reflector)
        }
        XCTAssert(transformer.reflector == nil)
    }
    
    func testSetProperty() {
        class Test: Reflection {
            @objc var name = ""
            @objc var nested: Test?
        }
        
        do {
            let test = Test()
            let reflector = Reflector()
            let properties = try reflector.reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == .optional(.unknown(Test.self)))
            try reflector.set(value: ["name": "success"], for: properties.last!, on: test)
            XCTAssert(test.nested?.name == "success")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNestedInDictionary() {
        class Test: Reflection {
            @objc var name = ""
            @objc var nested: [String: Test] = [:]
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
            let reflector = Reflector()
            let properties = try reflector.reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.count == 2)
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == .dictionary(.unknown(Test.self)))
            try reflector.set(value: nestedDictionary, for: properties.last!, on: test)
            XCTAssert(test.nested["bob"]?.name == "Bob")
            XCTAssert(test.nested["alice"]?.name == "Alice")
            XCTAssert(test.nested.count == 2)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testNestedArrayAndDictionary() {
        class Test: Reflection {
            @objc var name = ""
            @objc var nested: [[String: Test]] = []
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
            let reflector = Reflector()
            let properties = try reflector.reflect(test)
            XCTAssert(properties.first?.name == "name")
            XCTAssert(properties.count == 2)
            XCTAssert(properties.last?.name == "nested")
            XCTAssert(properties.last?.type == .array(.dictionary(.unknown(Test.self))))
            try reflector.set(value: nestedArray, for: properties.last!, on: test)
            if test.nested.count == 2 {
                XCTAssert(test.nested[0]["bob"]?.name == "Bob")
                XCTAssert(test.nested[0]["alice"]?.name == "Alice")
                XCTAssert(test.nested[1]["robert"]?.name == "Robert")
                XCTAssert(test.nested[1]["alicia"]?.name == "Alicia")
            } else {
                XCTFail("Count is wrong.")
            }
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testBasicSerialization() {
        class Car: Reflection {
            @objc var make = ""
            @objc var model = ""
            @objc var year = 0
            @objc var dealership = false
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
            @objc var make: String? = "wrong"
            @objc var model = ""
            @objc var year = 0
            @objc var dealership = false
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
            @objc var make = ""
            @objc var model = ""
            @objc var year = 0
            @objc var dealership = false
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
            @objc var name = ""
            @objc var friends: [Person] = []
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
            @objc var name = ""
            @objc var friends: [String: [String: Person]] = [:]
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
            @objc var person_name = ""
            @objc var pet: Pet?
        }
        
        class Pet: NSObject, Reflectable {
            @objc var pet_name = ""
            
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
            @objc var make = ""
            @objc var model = ""
            @objc var year = 0
            @objc var dealership = false
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
            XCTAssert(expected == .number(Int.self))
            
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
            @objc var name = ""
            @objc var age = 0
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
            @objc var name = ""
            
            convenience init(name: String) {
                self.init()
                self.name = name
            }
        }
        
        class Person: Reflection {
            @objc var name = ""
            @objc var age = 0
            @objc var born = Date()
            @objc var visitDates: [Date] = []
            @objc var pets: [Pet] = []
            @objc var bestFriend: Person?
            @objc var upgradedAt: Date?
            
            override class func config(_ c: PropertyConfig) {
                c["born"] = [.transformed(DateTransformer())]
                c["visitDates"] = [.transformed(DateTransformer()), .serializedName("visit_dates")]
                c["upgradedAt"] = [.transformed(DateTransformer()), .serializedName("upgraded_at")]
                c["bestFriend"] = [.serializedName("best_friend")]
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
            XCTAssert(dates?[0] == DateTransformer().formatter.string(from: now))
            XCTAssert(dates?[1] == DateTransformer().formatter.string(from: date2))
            XCTAssert(dates?[2] == DateTransformer().formatter.string(from: date3))
            
            let pets = dictionary["pets"] as? [[String: Any]]
            XCTAssert(pets?.count == 2)
            XCTAssert(pets?[0]["name"] as? String == "Fifi")
            XCTAssert(pets?[1]["name"] as? String == "Tiger")
            
            let bf = dictionary["best_friend"] as? [String: Any]
            XCTAssert(bf?["name"] as? String == "Bob")
            XCTAssert(bf?["age"] as? Int == 2)
            XCTAssert(bf?["born"] as? String == DateTransformer().formatter.string(from: bestFriend.born))
            XCTAssert(bf?["upgraded_at"] as? String == DateTransformer().formatter.string(from: bestFriend.upgradedAt!))
            
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
            @objc var name = ""
        }
        let t = Test()
        do {
            let properties = try Reflector.shared.reflect(t)
            XCTAssert(properties.count == 1 && properties.first?.name == "name")
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testOptionalNested() {
        class LoginResponse: Reflection {
            class LoginSuccessResponse: Reflection {
                @objc var user_id = ""
                @objc var role = ""
            }
            
            @objc var success: LoginSuccessResponse?
            @objc var error: String?
        }
        
        let builder = Builder.dry()
        let function = builder.makeRequest(
            method: .post,
            endpoint: "endpoint/",
            args: (),
            response: LoginResponse.self,
            testProvider: { (creation, starting, request) in
                return ClientResponse(
                    url: request.url!,
                data: ("{\n" +
                "  \"success\": {\n" +
                "    \"user_id\": \"123\"," +
                "    \"role\": \"freelancer\"\n" +
                "  }\n" +
                    "}").data(using: .utf8)!,
                    headers: [:],
                    status: 200,
                    error: nil
                )
            }
        )
        let response = function(()).perform()
        XCTAssert(response.body?.success?.user_id == "123")
        XCTAssert(response.body?.success?.role == "freelancer")
        XCTAssert(response.isSuccessful)
    }
    
    func testCopyReflection() {
        class Person: Reflection {
            @objc var first_name = ""
            @objc var last_name = ""
            @objc var nickname: String?
            @objc var image_url: URL?
            @objc var friends: [Person]?
        }
        
        let data = "{\"first_name\":\"Bobby\",\"last_name\":\"Jones\",\"nickname\":null,\"image_url\":\"https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png\",\"friends\":[{\"first_name\":\"Alice\",\"last_name\":\"Rogers\"}]}".data(using: .utf8)!
        do {
            let person1 = try Reflector().convert(fromJSONDictionaryData: data, to: Person.self) as! Person
            let copy1 = try Reflector().copy(person1)
            XCTAssert(person1 !== copy1)
            XCTAssert(person1.first_name == "Bobby")
            XCTAssert(copy1.first_name == person1.first_name)
            XCTAssert(person1.last_name == "Jones")
            XCTAssert(copy1.last_name == person1.last_name)
            XCTAssert(person1.nickname == nil)
            XCTAssert(copy1.nickname == person1.nickname)
            XCTAssert(person1.image_url == URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png")!)
            XCTAssert(copy1.image_url == person1.image_url)
            XCTAssert(person1.friends?.count == 1)
            XCTAssert(copy1.friends?.count == person1.friends?.count)
            if let friend = person1.friends?.first, let copyFriend = copy1.friends?.first {
                XCTAssert(friend.first_name == "Alice")
                XCTAssert(copyFriend.first_name == friend.first_name)
                XCTAssert(friend.last_name == "Rogers")
                XCTAssert(copyFriend.last_name == friend.last_name)
                XCTAssert(friend.nickname == nil)
                XCTAssert(copyFriend.nickname == friend.nickname)
                XCTAssert(friend.image_url == nil)
                XCTAssert(copyFriend.image_url == friend.image_url)
                XCTAssert(friend.friends == nil)
                XCTAssert(copyFriend.friends == nil && nil == friend.friends)
            }
            
            let data1 = try Reflector().convertToJSONDictionaryData(from: person1)
            let data2 = try Reflector().convertToJSONDictionaryData(from: copy1)
            XCTAssert(data1 == data2)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testDiff() {
        class Person: Reflection {
            @objc var first_name = ""
            @objc var last_name = ""
            @objc var nickname: String?
            @objc var image_url: URL?
            @objc var favorite_friend: Person?
            @objc var friends: [Person]?
        }
        
        let p1 = Person()
        let p2 = Person()
        p2.first_name = "Alice"
        p2.last_name = "Jones"
        p2.nickname = "Ali"
        p1.favorite_friend = Person()
        p1.favorite_friend!.first_name = "Bobby"
        p1.favorite_friend!.last_name = "Rogers"
        
        do {
            let diff_p1_p2 = try Reflector().diff(from: p1, to: p2)
            XCTAssert(Set(diff_p1_p2.keys) == Set(["first_name", "last_name", "nickname", "favorite_friend"]))
            XCTAssert(diff_p1_p2["first_name"] as? String == "Alice")
            XCTAssert(diff_p1_p2["last_name"] as? String == "Jones")
            XCTAssert(diff_p1_p2["nickname"] as? String == "Ali")
            XCTAssert(diff_p1_p2["favorite_friend"] is NSNull)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let diff_p2_p1 = try Reflector().diff(from: p2, to: p1)
            XCTAssert(Set(diff_p2_p1.keys) == Set(["first_name", "last_name", "nickname", "favorite_friend"]))
            XCTAssert(diff_p2_p1["first_name"] as? String == "")
            XCTAssert(diff_p2_p1["last_name"] as? String == "")
            XCTAssert(diff_p2_p1["nickname"] is NSNull)
            XCTAssert(diff_p2_p1["favorite_friend"] as? NSDictionary == [
                "first_name": "Bobby",
                "last_name": "Rogers",
                "nickname": NSNull(),
                "image_url": NSNull(),
                "favorite_friend": NSNull(),
                "friends": NSNull()
                ] as NSDictionary)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let p1 = Person()
            p1.favorite_friend = Person()
            p1.favorite_friend!.first_name = "Bob"
            let p2 = Person()
            p2.favorite_friend = Person()
            p2.favorite_friend!.first_name = "Bobby"
            let diff_p1_p2 = try Reflector().diff(from: p1, to: p2)
            XCTAssert(diff_p1_p2 as NSDictionary == [
                "favorite_friend": [
                    "first_name": "Bobby"
                    ] as NSDictionary
                ])
            
            let diff_p2_p1 = try Reflector().diff(from: p2, to: p1)
            XCTAssert(diff_p2_p1 as NSDictionary == [
                "favorite_friend": [
                    "first_name": "Bob"
                    ] as NSDictionary
                ])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let p1 = Person()
            let p2 = Person()
            p1.friends = [
                Person()
            ]
            p2.friends = [
                Person()
            ]
            
            XCTAssert(try Reflector().diff(from: p1, to: p2).isEmpty)
            XCTAssert(try Reflector().diff(from: p2, to: p1).isEmpty)
            
            p2.friends![0].first_name = "Actually has one"
            XCTAssert(try Reflector().diff(from: p1, to: p2) as NSDictionary == ["friends": [[
                "first_name": "Actually has one",
                "last_name": "",
                "nickname": NSNull(),
                "image_url": NSNull(),
                "favorite_friend": NSNull(),
                "friends": NSNull()
                ]]] as NSDictionary)
            XCTAssert(try Reflector().diff(from: p2, to: p1) as NSDictionary == ["friends": [[
                "first_name": "",
                "last_name": "",
                "nickname": NSNull(),
                "image_url": NSNull(),
                "favorite_friend": NSNull(),
                "friends": NSNull()
                ]]] as NSDictionary)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        
        do {
            let p1 = Person()
            p1.favorite_friend = Person()
            let p2 = Person()
            p2.favorite_friend = Person()
            p2.favorite_friend!.first_name = "Bob"
            let diff_p1_p2 = try Reflector().diff(from: p1, to: p2)
            XCTAssert(diff_p1_p2 as NSDictionary == [
                "favorite_friend": [
                    "first_name": "Bob"
                ]
                ] as NSDictionary)
            
            let diff_p2_p1 = try Reflector().diff(from: p2, to: p1)
            XCTAssert(diff_p2_p1 as NSDictionary == [
                "favorite_friend": [
                    "first_name": ""
                ]
                ] as NSDictionary)
            
            let diff_p2_p1_nongranular = try Reflector().diff(from: p2, to: p1, granular: false)
            XCTAssert(diff_p2_p1_nongranular as NSDictionary == [
                "favorite_friend": [
                    "first_name": "",
                    "last_name": "",
                    "nickname": NSNull(),
                    "image_url": NSNull(),
                    "favorite_friend": NSNull(),
                    "friends": NSNull()
                ]
                ] as NSDictionary)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testUpdate() {
        class Person: Reflection {
            @objc var name = ""
            @objc var age = 0
            
            @objc var friend: Person?
        }
        
        class Dog: Reflection {
            @objc var name: String?
            @objc var age: NSNumber?
            
            @objc var friend: Dog?
        }
        
        let person = Person()
        
        let dog = Dog()
        dog.name = "Scrufus"
        dog.age = 13
        
        dog.friend = Dog()
        dog.friend!.name = "Bubbles"
        dog.friend!.age = 9
        
        do {
            try Reflector().update(person, with: dog)
            XCTAssert(person.name == "Scrufus")
            XCTAssert(person.age == 13)
            XCTAssert(person.friend!.name == "Bubbles")
            XCTAssert(person.friend!.age == 9)
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
        return DateTransformer().formatter.string(from: self)
    }
}
