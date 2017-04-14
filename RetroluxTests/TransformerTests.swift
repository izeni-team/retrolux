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
        let transformer = Transformer<Date, String>(setter: { (value) in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            guard let date = formatter.date(from: value) else {
                throw ReflectorSerializationError.keyNotFound(propertyName: "", key: "", forClass: Any.self)
            }
            return date
        }) { (date) -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.string(from: date)
        }
        
        class Person: NSObject, Reflectable {
            var born = Date()
            
            required override init() {
                super.init()
            }
        }
        
        XCTAssert(transformer.supports(propertyType: .unknown(Date.self)))
        XCTAssert(transformer.supports(value: "2015-02-03'T'12:00:00Z"))
        
//        let p = Person()
//        let property = Property(
//            type: .transformed(propertyType: Date.self, dataType: String.self, transformer: transformer),
//            name: "born",
//            required: <#T##Bool#>,
//            mappedTo: <#T##String#>,
//            transformer: <#T##ValueTransformer?#>
//        )
//        p.born = transformer.set(value: "2010-01-02'T'12:01:02Z", for: property, instance: <#T##Reflectable#>)
    }
}
