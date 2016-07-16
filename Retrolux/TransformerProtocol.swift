//
//  TransformerProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/13/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum TransformationDirection {
    case ToNetwork
    case FromNetwork
}

protocol TransformerProtocol {
    func transform(inout value: Any?, toType type: PropertyType, forProperty: Property, direction: TransformationDirection) -> Bool
}

enum TransformationResult {
    case Transformed(value: Any)
    case NoTransformation
}

extension TransformerProtocol {
//    func transformRecursively(inputValue: Any, inputType: PropertyType, targetType: PropertyType, direction: TransformationDirection) -> TransformationResult {
//        switch inputType {
//        case .anyObject:
//            return .NoTransformation
//        case .array(let inputInnerType):
//            if case .array(let targetInnerType) = targetType, let array = inputValue as? [Any] {
//                var copy: [Any]!
//                
//                for (index, innerValue) in array.enumerate() {
//                    let output = transformRecursively(innerValue, inputType: inputInnerType, targetType: targetInnerType, direction: direction)
//                    if case TransformationResult.Transformed(let transformed) = output {
//                        if copy == nil {
//                            copy = array
//                        }
//                        copy[index] = transformed
//                    }
//                }
//                
//                if copy != nil {
//                    return TransformationResult.Transformed(value: copy)
//                }
//            }
//        case .bool:
//            if case .bool = targetType {
//                return .NoTransformation
//            }
//        case .dictionary(let inputInnerType):
//            guard case .dictionary(let targetInnerType) = targetType else {
//                return .NoTransformation
//            }
//        }
//        
//        return .NoTransformation
//    }
}

class Transformer: TransformerProtocol {
    func transform(inout value: Any?, toType type: PropertyType, forProperty: Property, direction: TransformationDirection) -> Bool {
        value = "TRANFORMERS! ROBOTS IN DISGUISE!!!"
        return true
    }
}