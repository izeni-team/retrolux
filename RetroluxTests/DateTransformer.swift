//
//  DateTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import Retrolux

enum DateTransformerError: Error {
    case invalidType
    case invalidDateFormat
}

class DateTransformer: Retrolux.ValueTransformer {
    static let shared = DateTransformer()
    
    let formatter = { () -> DateFormatter in
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'hh:mm:ss.SSSZZZZ"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    
    func supports(targetType: Any.Type) -> Bool {
        return targetType is Date.Type
    }
    
    func transform(_ value: Any, targetType: Any.Type, direction: ValueTransformerDirection) throws -> Any {
        switch direction {
        case .forwards:
            guard let string = value as? String else {
                throw DateTransformerError.invalidType
            }
            guard let date = formatter.date(from: string) else {
                throw DateTransformerError.invalidDateFormat
            }
            return date
        case .backwards:
            return formatter.string(from: value as! Date)
        }
    }
}
