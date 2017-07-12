//
//  DateTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

open class DateTransformer: NestedTransformer {
    public typealias TypeOfProperty = Date
    public typealias TypeOfData = String
    
    public enum Error: Swift.Error {
        case invalidDateFormat
    }
    
    open let formatter: DateFormatter
    
    public init(format: String = "yyyy-MM-dd'T'hh:mm:ss.SSSZZZZ") {
        formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US")
    }
    
    open func setter(_ dataValue: String, type: Any.Type) throws -> Date {
        guard let date = formatter.date(from: dataValue) else {
            throw Error.invalidDateFormat
        }
        return date
    }
    
    open func getter(_ propertyValue: Date) throws -> String {
        return formatter.string(from: propertyValue)
    }
}
