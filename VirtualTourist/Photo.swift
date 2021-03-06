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
	 @NSManaged var fetchedImage: Bool
	 var fetchInProgress = false
	
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
	
	// MARK:  fetch the actual image from the server
	
	func fetchImageData(filePath: String, completionHandler: (fetchComplete: Bool?, error: NSError?) ->  Void) {
		if !fetchedImage && !fetchInProgress {
			fetchInProgress = true
			
			let url = NSURL(string: filePath)! //The filePath will be the url_m of the image
			let request = NSURLRequest(URL: url)
			
			NSURLSession.sharedSession().dataTaskWithRequest(request) {data, response, error in
				if let error = error {
					completionHandler(fetchComplete: false, error: error)
				} else {
					self.image = UIImage(data: data!)
					completionHandler(fetchComplete: true, error: nil)
				}
				self.fetchInProgress = false
				}
				.resume()
		}
	}
	
	//MARK: delete image from documents directory
	
	var imageInDocumentsDirectory: NSURL {
		let documentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		return documentsDirectoryURL.URLByAppendingPathComponent(imageId)
	}
	
	override func prepareForDeletion() {
		super.prepareForDeletion()
		if NSFileManager.defaultManager().fileExistsAtPath(imageInDocumentsDirectory.path!) {
			do {
				try NSFileManager.defaultManager().removeItemAtURL(imageInDocumentsDirectory)
			} catch {
				print("Error removing image: \(imageId)")
			}
		}
	}
}
