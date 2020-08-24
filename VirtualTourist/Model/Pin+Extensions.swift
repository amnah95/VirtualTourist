//
//  Pin+Extensions.swift
//  VirtualTourist
//
//  Created by Amnah on 8/24/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}

