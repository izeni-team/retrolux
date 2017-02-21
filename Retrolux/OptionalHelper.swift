//
//  OptionalHelper.swift
//  Retrolux
//
//  Created by Bryan Henderson on 2/21/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

protocol OptionalHelper {
    var type: Any.Type { get }
    var value: Any? { get }
}

extension Optional: OptionalHelper {
    var type: Any.Type {
        return Wrapped.self
    }
    
    var value: Any? {
        if case Optional.some(let wrapped) = self {
            return wrapped
        }
        return nil
    }
}
