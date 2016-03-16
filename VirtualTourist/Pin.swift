//
//  Pin.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Pin: NSObject, MKAnnotation {
	
	var coordinate: CLLocationCoordinate2D {
		get {
			let location = CLLocationCoordinate2DMake(latitude, longitude)
			return location
		}
		set { //set is required for dragging the pin
			latitude = newValue.latitude
			longitude = newValue.longitude
		}
	}
	
	var latitude: CLLocationDegrees
	var longitude: CLLocationDegrees
	var photos: [Photo]?
	
	init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
}
