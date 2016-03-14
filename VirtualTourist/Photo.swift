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
	 var imageName: String
	 var remotePath: String
//	 var pin: Pin?
	
	var image: UIImage? {
		get {
			return FlickrClient.Caches.imageCache.imageWithIdentifier(remotePath)
		}
		
		set {
			FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: remotePath)
			print("i have been set !")
		}
	}

	init(imageName: String, remotePath: String) {

		self.imageName = imageName
		self.remotePath = remotePath
	}
	
}
