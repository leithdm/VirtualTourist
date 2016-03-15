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

class Photo {
	 var imageId: String
	 var imageURL: String
	 var pin: Pin?
	
	init(dictionary: [String: AnyObject]) {

		imageId = dictionary["url_m"] as! String
		imageURL = dictionary["id"] as! String
	}
	
	//images are stored in an imageCache, in the Documents Directory. 
	var image: UIImage? {
		get {
			print("get")
			return FlickrClient.Caches.imageCache.imageWithIdentifier("\(imageId).jpg")
		}
		
		set {
			print("set")
			FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: "\(imageId).jpg")
		}
	}
	
}
