//
//  ClientResponse.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct ClientResponse {
    let data: Data?
    let response: URLResponse?
    let error: Error?
    
    var status: Int? {
        return (response as? HTTPURLResponse)?.statusCode
    }
}
