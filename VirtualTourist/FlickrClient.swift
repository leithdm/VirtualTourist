//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Darren Leith on 13/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import Foundation

class FlickrClient {
	
	static let sharedInstance = FlickrClient()
	let session = NSURLSession.sharedSession()
	
	struct Flickr {
		static let APIScheme = "https"
		static let APIHost = "api.flickr.com"
		static let APIPath = "/services/rest"
		static let SearchBBoxHalfWidth = 1.0
		static let SearchBBoxHalfHeight = 1.0
		static let SearchLatRange = (-90.0, 90.0)
		static let SearchLonRange = (-180.0, 180.0)
	}
	
	
	// MARK: Flickr Parameter Keys
	struct FlickrParameterKeys {
		static let Method = "method"
		static let APIKey = "api_key"
		static let Extras = "extras"
		static let Format = "format"
		static let NoJSONCallback = "nojsoncallback"
		static let SafeSearch = "safe_search"
		static let BoundingBox = "bbox"
		static let PhotosPerPage = "per_page"
	}
	
	struct FlickrParameterValues {
		static let SearchMethod = "flickr.photos.search"
		static let APIKey = "fd24760b02ba530ea261db0a3ab9b09e"
		static let ResponseFormat = "json"
		static let DisableJSONCallback = "1" /* 1 means "yes" */
		static let MediumURL = "url_m"
		static let UseSafeSearch = "1"
		static let PhotosPerPage = "21"
	}
	
	// MARK: Flickr Response Keys
	struct FlickrResponseKeys {
		static let Status = "stat"
		static let Photos = "photos"
		static let Photo = "photo"
	}
	
	// MARK: Flickr Response Values
	struct FlickrResponseValues {
		static let OKStatus = "ok"
	}
	
	struct Caches {
		static let imageCache = ImageCache()
	}
	

	//MARK: download photo properties from the server. Note this does NOT download the image
	
	func downloadPhotoProperties(pin: Pin, completionHandler: (data: [[String: AnyObject]]?, error: String?) -> Void) {
		
		let methodParameters = [
			FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
			FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
			FlickrParameterKeys.BoundingBox: bboxString(pin.latitude, longitude: pin.longitude),
			FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
			FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
			FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
			FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
			FlickrParameterKeys.PhotosPerPage: FlickrParameterValues.PhotosPerPage
		]
		
		let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			

			guard (error == nil) else {
				completionHandler(data: nil, error: "There was an error with your request: \(error?.localizedDescription)")
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				completionHandler(data: nil, error: "Your request returned a status code other than 2xx!")
				return
			}
			
			guard let data = data else {
				completionHandler(data: nil, error: "No data was returned by the request!")
				return
			}
			
			// parse the data
			self.parseSearchForPhotos(data, completionHandler: completionHandler)
		}
		task.resume()
	}
	
	//MARK: parse the search for photos
	
	func parseSearchForPhotos(data: NSData, completionHandler: (result: [[String: AnyObject]]?, error: String?) -> Void) {
		
		var parsedResult: AnyObject!
		
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
		} catch {
			completionHandler(result: nil, error: "Could not parse the data as JSON: '\(data)'")
			return
		}
		
		guard let stat = parsedResult[FlickrResponseKeys.Status] as? String where stat == FlickrResponseValues.OKStatus else {
			completionHandler(result: nil, error: "Flickr API returned an error. See error code and message in \(parsedResult)")
			return
		}
		
		guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
			completionHandler(result: nil, error: "Cannot find keys '\(FlickrResponseKeys.Photos)' in \(parsedResult)")
			return
		}
		
		guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
			completionHandler(result: nil, error: "Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
			return
		}
		
		if photosArray.count == 0 {
			completionHandler(result: nil, error: "No photos found. Search again")
			return
		} else {
			completionHandler(result: photosArray, error: nil)
		}
	}
	
	
	// MARK:  returns a Task for downloading images from the server.
	
	func taskForDownloadingImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
		
		let url = NSURL(string: filePath)! //The filePath will be the url_m of the image
		let request = NSURLRequest(URL: url)
	
		let task = session.dataTaskWithRequest(request) {data, response, downloadError in
			if let error = downloadError {
				completionHandler(imageData: nil, error: error)
			} else {
				completionHandler(imageData: data, error: nil)
			}
		}
		task.resume()
		return task
	}
	
	//MARK: - URL from Parameters
	
	private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
		let components = NSURLComponents()
		components.scheme = Flickr.APIScheme
		components.host = Flickr.APIHost
		components.path = Flickr.APIPath
		components.queryItems = [NSURLQueryItem]()
		
		for (key, value) in parameters {
			let queryItem = NSURLQueryItem(name: key, value: "\(value)")
			components.queryItems!.append(queryItem)
		}
		return components.URL!
	}
	
	//MARK: - bounding box
	
	private func bboxString(latitude: Double, longitude: Double) -> String {
		// ensure bbox is bounded by minimum and maximums
		let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
		let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
		let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
		let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
		return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
	}
	
	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
}