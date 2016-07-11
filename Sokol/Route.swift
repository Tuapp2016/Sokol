//
//  Route.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 04/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import UIKit

class Route:NSObject,NSCopying{
    var name:String
    var descriptionRoute:String
    var annotations = [SokolAnnotation]()
    var id:String
    
    init(id:String,name:String,description:String,annotations:[SokolAnnotation]){
        self.id = id
        self.name = name
        self.descriptionRoute = description
        self.annotations = annotations
    }
    func copyWithZone(zone: NSZone) -> AnyObject {
        let copyRoute = Route(id: self.id, name: self.name, description: self.descriptionRoute, annotations: self.annotations)
        return copyRoute
    }
    
}