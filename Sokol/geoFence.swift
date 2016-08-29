//
//  Geofence.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 11/08/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import MapKit

class Geofence:CLCircularRegion{
    let sokolAnnotation:SokolAnnotation
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String,sokolAnnotation:SokolAnnotation) {
        self.sokolAnnotation = sokolAnnotation
        super.init(center: center, radius: radius, identifier: identifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}