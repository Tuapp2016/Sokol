//
//  SmallCache.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 12/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

class SmallCache{
    var cacheOpertaions:[String:[String:String]] = [:]
    static let sharedInstance = SmallCache(cacheOpertaions: nil)
    private init(cacheOpertaions:[String:[String:String]]?) {
        if let a = cacheOpertaions{
            self.cacheOpertaions = a
        }else{
            self.cacheOpertaions = [:]
        }
    }
    
}