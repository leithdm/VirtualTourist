//
//  Photo.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//
import Foundation
import UIKit
import CoreData

class Photo: NSManagedObject {
	
	 @NSManaged var imageId: String
	 @NSManaged var imageURL: String
	 @NSManaged var pin: Pin?
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
		
		let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
		super.init(entity: entity, insertIntoManagedObjectContext: context)

		imageId = dictionary[FlickrClient.FlickrParameterKeys.Id] as! String
		
		//convert the downloaded url_m to a small version of the image by replacing *.jpg" with *_s.jpg*
		imageURL = {
			let url = dictionary[FlickrClient.FlickrParameterKeys.URL_M] as! String
			return url.stringByReplacingOccurrencesOfString(FlickrClient.FlickrParameterKeys.JPEG, withString: FlickrClient.FlickrParameterKeys.smallJPEG)
		}()
	}
	
	//images are retrieved/set via the Documents directory
	var image: UIImage? {
		get {
			return FlickrClient.Caches.imageCache.imageWithIdentifier("\(imageId)")
		}
		
		set {
			FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: "\(imageId)") //newValue being the default value
		}
	}
	
}
