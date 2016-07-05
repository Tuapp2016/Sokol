//
//  Route.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 04/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import UIKit

class Route{
    var name:String
    var description:String
    var annotations = [SokolAnnotation]()
    var id:String
    
    init(id:String,name:String,description:String,annotations:[SokolAnnotation]){
        self.id = id
        self.name = name
        self.description = description
        self.annotations = annotations
    }
    
}