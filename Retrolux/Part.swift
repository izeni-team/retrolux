//
//  Part.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import UIKit

public struct Part: MultipartEncodeable {
    private var mimeType: String?
    private var filename: String?
    private var name: String?
    private var data: Data?
    
    public init(name: String, filename: String, mimeType: String) {
        self.name = name
        self.filename = filename
        self.mimeType = mimeType
    }
    
    public init(name: String, mimeType: String) {
        self.name = name
        self.mimeType = mimeType
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public init(_ data: Data) {
        self.data = data
    }
    
    public init(_ string: String) {
        self.data = string.data(using: .utf8)!
    }
    
    public static func encode(with arg: BuilderArg, using encoder: MultipartFormData) {
        if let creation = arg.creation as? Part, let starting = arg.starting as? Part {
            if let filename = creation.filename, let mimeType = creation.mimeType {
                encoder.append(starting.data!, withName: creation.name!, fileName: filename, mimeType: mimeType)
            } else if let mimeType = creation.mimeType {
                encoder.append(starting.data!, withName: creation.name!, mimeType: mimeType)
            } else {
                encoder.append(starting.data!, withName: creation.name!)
            }
        }
    }
}
