//
//  DateTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux

class DateTransformer: NestedTransformer<Date, String> {
    enum Error: Swift.Error {
        case invalidDateFormat
    }
    
    static let formatter = { () -> Foundation.DateFormatter in
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'hh:mm:ss.SSSZZZZ"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    
    convenience init() {
        self.init(setter: { (string, _) -> Date in
            guard let date = DateTransformer.formatter.date(from: string) else {
                throw Error.invalidDateFormat
            }
            return date
        }, getter: { (date) -> String in
            return DateTransformer.formatter.string(from: date)
        })
    }
}
