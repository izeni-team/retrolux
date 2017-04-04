//
//  ClientResponseExtensions.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux

extension ClientResponse {
    init(base: ClientResponse, status: Int?, data: Data?, error: Error? = nil) {
        let response: URLResponse?
        
        if let httpUrlResponse = base.response as? HTTPURLResponse {
            response = HTTPURLResponse(
                url: httpUrlResponse.url!,
                statusCode: status ?? 0,
                httpVersion: "1.1",
                headerFields: httpUrlResponse.allHeaderFields as? [String: String]
            )
        } else {
            response = base.response
        }
        
        self.init(data: data, response: response, error: error)
    }
}
