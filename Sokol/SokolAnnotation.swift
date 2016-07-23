//
//  SokolAnnotation.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 03/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class SokolAnnotation:NSObject,MKAnnotation{
    var coordinate:CLLocationCoordinate2D
    var title:String?
    var subtitle: String?
    var checkPoint:Bool
    var id:String?
    init (coordinate:CLLocationCoordinate2D,title:String,subtitle:String,checkPoint:Bool,id:String){
        self.title = title
        self.coordinate = coordinate
        self.subtitle =  subtitle
        self.checkPoint = checkPoint
        self.id = id
        
    }
}
