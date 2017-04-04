//
//  InterpretedResponse.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum InterpretedResponse<T> {
    case success(T)
    case failure(Error)
}
