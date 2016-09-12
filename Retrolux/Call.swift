//
//  Call.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation


class Call<T> {
    var request: NSURLRequest?
    
    private var executed: Bool = false

    func enqueue(callback: (() -> T)!) {
        if callback == nil {
            // TODO: Handle/Throw Error for callback == nil
            return
        }
        
        if executed {
            // TODO: Handle/Throw Error for executed == true
            return
        }
        executed = true
        callback()
    }
  
    
    func isExecuted() -> Bool {
        return executed
    }
    
   }
