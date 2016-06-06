//
//  Retrolux.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/4/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum RetroluxException: ErrorType {
    case SerializerError(message: String)
}
//
//public enum HTTPMethod: String {
//    case GET = "GET"
//    case POST = "POST"
//}
//
//public struct RetroluxError {
//    enum ErrorType {
//        case Serializer
//        case Network
//        case Server
//    }
//    
//    let type: ErrorType
//    let description: String
//    let statusCode: Int?
//}
//
//public enum ObjectResponse<T: Serializable> {
//    case Success(object: T)
//    case Error(error: RetroluxError)
//}
//
//public enum ArrayResponse<T: Serializable> {
//    case Success(objects: Array<T>)
//    case Error(error: RetroluxError)
//}
//
//public enum EmptyResponse {
//    case Success
//    case Error(error: RetroluxError)
//}

public class Retrolux {
    public static let sharedInstance = Retrolux()
    public var serializer = Serializer()
    
    public class var serializer: Serializer {
        return sharedInstance.serializer
    }
}