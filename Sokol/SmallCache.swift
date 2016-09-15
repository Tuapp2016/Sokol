//
//  SmallCache.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 12/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

class SmallCache: NSObject,NSCoding{
    var cacheOperations:NSMutableDictionary = [:]
    static let sharedInstance = SmallCache(cacheOperations: nil)
    private init(cacheOperations:NSMutableDictionary?){
        if let a = cacheOperations{
            self.cacheOperations = a
        }
        super.init()
    }
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(cacheOperations,forKey: "sokolCache")
    }
    required convenience init?(coder aDecoder: NSCoder) {
        let cacheOperations = aDecoder.decodeObjectForKey("sokolCache") as! NSMutableDictionary
        
        self.init(cacheOperations: cacheOperations)
    }
    

    
}