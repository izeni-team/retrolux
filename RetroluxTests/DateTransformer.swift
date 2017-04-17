//
//  DateTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux

class DateTransformer: NestedTransformer {
    typealias TypeOfProperty = Date
    typealias TypeOfData = String
    
    enum Error: Swift.Error {
        case invalidDateFormat
    }
    
    static let formatter = { () -> Foundation.DateFormatter in
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'hh:mm:ss.SSSZZZZ"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    
    func setter(_ dataValue: String, type: Any.Type) throws -> Date {
        guard let date = DateTransformer.formatter.date(from: dataValue) else {
            throw Error.invalidDateFormat
        }
        return date
    }
    
    func getter(_ propertyValue: Date) throws -> String {
        return DateTransformer.formatter.string(from: propertyValue)
    }
}
