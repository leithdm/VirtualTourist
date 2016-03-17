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
import CoreData

class Pin: NSManagedObject, MKAnnotation {
	
	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var photos: [Photo]
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
		let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		
		self.latitude = latitude
		self.longitude = longitude
	}
	
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

	
}
