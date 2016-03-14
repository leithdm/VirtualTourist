//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Darren Leith on 13/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import Foundation

class FlickrClient {
	
	static let sharedInstancde = FlickrClient()
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
		static let GalleryID = "gallery_id"
		static let Extras = "extras"
		static let Format = "format"
		static let NoJSONCallback = "nojsoncallback"
		static let SafeSearch = "safe_search"
		static let Text = "text"
		static let BoundingBox = "bbox"
		static let Page = "page"
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
		static let Title = "title"
		static let MediumURL = "url_m"
		static let Pages = "pages"
		static let Total = "total"
	}
	
	// MARK: Flickr Response Values
	struct FlickrResponseValues {
		static let OKStatus = "ok"
	}
	
	struct Caches {
		static let imageCache = ImageCache()
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
	
	
	//MARK: - serach for photos
	
	func searchForPhotos(pin: Pin, completionHandler: (data: [[String: AnyObject]]?, error: String?) -> Void) {
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
			
			// if an error occurs, print it and re-enable the UI
			func displayError(error: String) {
				print(error)
			}
			
			/* GUARD: Was there an error? */
			guard (error == nil) else {
				completionHandler(data: nil, error: "There was an error with your request: \(error)")
				return
			}
			
			/* GUARD: Did we get a successful 2XX response? */
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				completionHandler(data: nil, error: "Your request returned a status code other than 2xx!")
				return
			}
			
			/* GUARD: Was there any data returned? */
			guard let data = data else {
				completionHandler(data: nil, error: "No data was returned by the request!")
				return
			}
			
			// parse the data
			
			self.parseSearchForPhotos(data, completionHandler: completionHandler)
		}
		task.resume()
	}
	
	func parseSearchForPhotos(data: NSData, completionHandler: (result: [[String: AnyObject]]?, error: String?) -> Void) {
		
		var parsedResult: AnyObject!
		
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
		} catch {
			completionHandler(result: nil, error: "Could not parse the data as JSON: '\(data)'")
			return
		}
		
		/* GUARD: Did Flickr return an error (stat != ok)? */
		guard let stat = parsedResult[FlickrResponseKeys.Status] as? String where stat == FlickrResponseValues.OKStatus else {
			completionHandler(result: nil, error: "Flickr API returned an error. See error code and message in \(parsedResult)")
			return
		}
		
		/* GUARD: Is "photos" key in our result? */
		guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
			completionHandler(result: nil, error: "Cannot find keys '\(FlickrResponseKeys.Photos)' in \(parsedResult)")
			return
		}
		
		/* GUARD: Is the "photo" key in photosDictionary? */
		guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
			completionHandler(result: nil, error: "Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
			return
		}
		
		
		/* GUARD: Is "pages" key in the photosDictionary? */
		/*
		guard let totalPages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
		completionHandler(result: nil, error: "Cannot find key '\(FlickrResponseKeys.Pages)' in \(photosDictionary)")
		return
		}
		// pick a random page!
		//			let pageLimit = min(totalPages, 40)
		//			let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
		//			self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage)
		*/
		
		if photosArray.count == 0 {
			completionHandler(result: nil, error: "No photos found. Search again")
			return
		} else {
			completionHandler(result: photosArray, error: nil)
		}
	}
	
	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
}