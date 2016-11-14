//
//  CareAnnotation.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/11/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CareAnnotation:NSObject,MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var id:String
    init(coordinate:CLLocationCoordinate2D,title:String,subtitle:String,id:String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.id = id
        
    }
}
