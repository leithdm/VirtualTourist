//
//  Photo.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//
import Foundation
import UIKit

class Photo {
	
	 var imageId: String
	 var imageURL: String
	 var pin: Pin?
	
	init(dictionary: [String: AnyObject]) {

		imageId = dictionary["id"] as! String
		imageURL = dictionary["url_m"] as! String
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
