//
//  AlignedArg.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

protocol AlignedSelfApplyingArg {
    func apply(to request: inout URLRequest, with alignedArg: Any)
}
