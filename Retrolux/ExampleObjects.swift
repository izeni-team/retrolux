//
//  ExampleObjects.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/6/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

class SomeCustomClass: NSObject {
    
}

// This is an object with a custom base class.
// You cannot subclass Person without breaking serialization though. See class below for more details.
class Person: SomeCustomClass, Serializable {
    required override init() {
        super.init()
    }
    
    var name: String? = ""
    var friend: Person?
    
    static let optionalProperties = ["friend"]
    
    override var description: String {
        if let f = friend {
            return "Person(name: \(name), friend: \(f))"
        } else {
            return "Person(name: \(name))"
        }
    }
}

// This model uses RetroluxObject as the base, which enables inheritance.
// If you have a custom base class, only the final subclass may be serializable, due to hard
// limitations of Swift protocols.
class ExampleObjectBase: RetroluxObject {
    var string = "(default value)"
    var string_opt: String? = "(default value)" // Optional properties may be nil without raising an error.
    var failure_string: String = "(default value)"
    var int = 0
    var float = 0.0
    var number_opt: NSNumber?
    var list_anyobject: [AnyObject]? = [] // The serializer understands what AnyObject means
    var strings_2d: [[AnyObject]] = []
    var date: NSDate?
    var dates: [NSDate] = []
    var date_dict: [String: NSDate] = [:]
    var date_dict_array: [String: [[String: NSDate]]] = [:]
    var craycray: [String: [String: [String: [Int]]]] = [:]
    var person: Person?
    var friends: [Person] = []
    var thing: AnyObject?
    var desc = ""
    
    // Ignored by the serializer, because it's not a stored property
    var thing_number: Int? {
        get {
            return thing as? Int
        }
        set {
            thing = newValue
        }
    }
    
    // Ignored by the serializer, because it's not a stored property
    var thing_string: String? {
        get {
            return thing as? String
        }
        set {
            thing = newValue
        }
    }
    
    // Any properties listed here will fallback to their default values if an error is raised while assigning it
    // a value from JSON. An error could be raised for over a dozen different reasons, including:
    // - Property is read-only
    // - Non-existant property can't be ignored
    // - Non-existant property can't be marked optional
    // - Missing key in JSON for property
    // - Having a subclass that is Serializable but not a RetroluxObject
    // - Marking a property as both ignored and optional
    // - Mapping a non-existant property
    // - Mapping multiple properties to the same JSON key
    // - Unsupported property type (supported types are Numbers, Dates, Dictionaries, Arrays, Strings, and other Objects)
    // - Having an optional primitive (i.e., Int?, Bool?) that can't be bridged to Objective-C
    // - JSON validation error (types in JSON didn't match type for property)
    // - Failing to convert a String into a Date
    // - Failing custom validation via validate()
    override class var optionalProperties: [String] {
        return ["failure_string"]
    }
    
    // Tell the serializer to look for the JSON key "description" when assigning the property "desc".
    // If you want to ignore a property, implement ignoredProperties instead.
    override class var mappedProperties: [String: String] {
        return ["desc": "description"]
    }
    
    override var description: String {
        return "\(self.dynamicType)(\n" +
            "  string: \(string)\n" +
            "  string_opt: \(string_opt)\n" +
            "  failure_string: \(failure_string)\n" +
            "  int: \(int)\n" +
            "  float: \(float)\n" +
            "  number_opt: \(number_opt)\n" +
            "  list_anyobject: \(list_anyobject)\n" +
            "  strings_2d: \(strings_2d)\n" +
            "  date: \(date)\n" +
            "  dates: \(dates)\n" +
            "  date_dict: \(date_dict)\n" +
            "  date_dict_array: \(date_dict_array)\n" +
            "  craycray: \(craycray)\n" +
            "  person: \(person)\n" +
            "  friends: \(friends)\n" +
            "  thing_number: \(thing_number)\n" +
            "  thing_string: \(thing_string)\n" +
            "  desc: \(desc)\n" +
        ")"
    }
}

// This object extends the base object and adds a property of its own.
class ExampleObject: ExampleObjectBase {
    var notSerializable: Bool? = nil // Not Objective-C compatible, so we must add it to ignoredProperties.
    var inherited: Bool = false
    
    override class var ignoredProperties: [String] {
        return super.ignoredProperties + ["notSerializable"]
    }
    
    override var description: String {
        return super.description + "inherited: \(inherited)"
    }
}

//
// Helper functions for the example. Exceptions are powerful, but not very user-friendly. :-)
//

func createObject<T: Serializable>(type: T.Type, fromDictionary dictionary: [String: AnyObject]) -> T? {
    do {
        return try T(dictionary: dictionary)
    } catch RetroluxException.SerializerError(let message) {
        print("Exception while converting dictionary into \(T.self):", message)
        return nil
    } catch let error {
        print("Unknown exception while converting dictionary into \(T.self): \(error)")
        return nil
    }
}

func createDictionary<T: Serializable>(fromObject object: T) -> [String: AnyObject]? {
    do {
        return try object.toDictionary()
    } catch RetroluxException.SerializerError(let message) {
        print("Exception while converting \(T.self) into a dictionary:", message)
        return nil
    } catch let error {
        print("Unknown exception while converting \(T.self) into a dictionary: \(error)")
        return nil
    }
}

func runExample() {
    func runExample() {
        let exampleDictionary: [String: AnyObject] = [
            "string": "Hello!",
            "string_opt": NSNull(),
            "failure_string": "",
            "int": 23,
            "float": 23.32,
            "thing": 2,
            "number_opt": NSNull(),
            "list_anyobject": [23, ["SURPRISE!"], NSNull()],
            "strings_2d": [["A", "B"], [2, "D"]],
            "date": "2015-04-23T12:03:00Z",
            "dates": ["2015-04-23T12:03:00Z", "2015-04-23T12:03:00Z"],
            "date_dict": ["test": "2015-04-23T12:03:00Z", "test2": "2015-04-23T12:03:00Z"],
            "date_dict_array": ["test": [["date": "2015-04-23T12:03:00Z"]]],
            "craycray": ["stuff": ["more_stuff": ["even_more_stuff": [1, 2, 3]]]],
            "person": [
                "name": "Bob",
                "whatever": true
            ],
            "friends": [
                ["name": NSNull()],
                ["name": "Jerry", "friend": ["name": "Ima Friend"]]
            ],
            "description": "Hello, this is a Model test",
            "inherited": true
        ]
        
        if let exampleObj = createObject(ExampleObject.self, fromDictionary: exampleDictionary) {
            print("exampleObj: \(exampleObj)")
            
            if let andBackToDictionary = createDictionary(fromObject: exampleObj) {
                print("\n\nexampleObj.toDictionary(): \(andBackToDictionary)")
            }
        } else {
            print("!testModel")
        }
    }
}