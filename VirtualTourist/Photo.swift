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
//	 var imageName: String
	 var remotePath: String
//	 var pin: Pin?
//	 var didFetchImageData: Bool
	
//	private let noPhotoAvailableImageData = NSData(data: UIImagePNGRepresentation(UIImage(named: "noPhotoAvailable")!)!)
//	var fetchInProgress = false
	
//	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
//		super.init(entity: entity, insertIntoManagedObjectContext: context)
//	}
	
	init(remotePath: String) {
//		let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
//		super.init(entity: entity, insertIntoManagedObjectContext: context)
//		self.imageName = imageName
		self.remotePath = remotePath
//		didFetchImageData = false
	}
	
//	var localURL: NSURL {
//		let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
//		return url.URLByAppendingPathComponent(imageName)
//	}
	
//	var imageData: NSData? {
//		var imageData: NSData? = nil
//		if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
//			imageData = NSData(contentsOfURL: localURL)
//		}
//		return imageData
//	}
	
//	func fetchImageData(completionHandler: (fetchComplete: Bool) -> Void) {
//		if didFetchImageData == false && fetchInProgress == false {
//			fetchInProgress = true
//			
//			if let url = NSURL(string: remotePath) {
//				NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
//					if self.managedObjectContext != nil {
//						if error != nil {
//							NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: self.noPhotoAvailableImageData, attributes: nil)
//						} else {
//							NSFileManager.defaultManager().createFileAtPath(self.localURL.path!, contents: data, attributes: nil)
//						}
//						self.didFetchImageData = true
//						completionHandler(fetchComplete: true)
//					} else {
//						completionHandler(fetchComplete: false)
//					}
//					self.fetchInProgress = false
//					}.resume()
//			}
//		}
//	}
	
//	override func prepareForDeletion() {
//		super.prepareForDeletion()
//		if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
//			do {
//				try NSFileManager.defaultManager().removeItemAtURL(localURL)
//			} catch {
//				NSLog("Couldn't remove image: \(imageName)")
//			}
//		}
//	}
}
