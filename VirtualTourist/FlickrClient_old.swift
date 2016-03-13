//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import Foundation

//let bboxEdge = 0.005
//let bboxEdge = 0.01
//let bboxEdge = 0.05
let bboxEdge = 0.1

class FlickrClient {
	
	static let sharedInstance = FlickrClient()
	private let session = NSURLSession.sharedSession()
	var additionalHTTPHeaderFields: [String:String]? = nil
	
	var additionalMethodParams: [String:AnyObject]? =  [
		"api_key": Constants.restApiKey,
		"format": "json",
		"nojsoncallback": 1,
		"safe_search": 1,
	]
	
	private struct ErrorMessage {
		static let domain = "VirtualTourist"
		static let noInternet = "You appear to be offline, please connect to the Internet to use Virtual Tourist."
		static let invalidURL = "Invalid URL"
		static let emptyURL = "Empty URL"
		static let jsonParseFailed = "Could not parse JSON"
	}
	
	private struct Constants {
		static let baseURL = "https://api.flickr.com/services/rest/"
		static let photoSourceURL = "https://farm{farmId}.staticflickr.com/{serverId}/{photoId}_{secret}_{imageSize}.jpg"
		static let restApiKey = "fd24760b02ba530ea261db0a3ab9b09e" //my API key
		static let photosPerPage = 24
		static let maxNumberOfResultsReturnedByFlickr = 4000 //default value on FlickrAPI
	}
	
	private struct Methods {
		static let photosSearch = "flickr.photos.search"
	}
	
	private struct ImageSize {
		static let smallSquare = "s"
		static let largeSquare = "q"
		static let thumbnail   = "t"
		static let small240    = "m"
		static let small320    = "n"
		static let medium500   = "-"
		static let medium640   = "z"
		static let medium800   = "c"
		static let large1024   = "b"
		static let large1600   = "h"
		static let large2048   = "k"
		static let original    = "o"
	}
	
	//MARK: - photo search
	
	func photosSearch(pin: Pin, completionHandler: (photoProperties: [[String:String]]?, errorString: String?) -> Void) {
		
		let bboxParms = photoSearchGetBboxParams(pin.latitude, longitude: pin.longitude)
		photoSearchGetRandomPage(bboxParms) { randomPageNumber, errorString in
			if errorString != nil {
				completionHandler(photoProperties: nil, errorString: errorString)
			} else {
				let methodParams: [String:AnyObject] = [
					"method": Methods.photosSearch,
					"bbox": bboxParms,
					"per_page": Constants.photosPerPage,
					"page": randomPageNumber!
				]
				let url = Constants.baseURL + self.urlParamsFromDictionary(methodParams)
				self.httpGet(url) { result, error in
					if error != nil {
						completionHandler(photoProperties: nil, errorString: error?.localizedDescription)
					} else {
						if let jsonPhotosDictionary = result["photos"] as? NSDictionary {
							if let jsonPhotoDataArray = jsonPhotosDictionary["photo"] as? NSArray {
								var photoProperties = [[String:String]]()
								for jsonPhotoData in jsonPhotoDataArray {
									if let photoProperty = self.photoParamsToProperties(jsonPhotoData as! NSDictionary) {
										photoProperties.append(photoProperty)
									}
								}
								print(photoProperties)
								completionHandler(photoProperties: photoProperties, errorString: nil)
							} else {
								completionHandler(photoProperties: nil, errorString: "Couldn't get photo set from Flickr. Please try again later or try a different location.")
							}
						} else {
							completionHandler(photoProperties: nil, errorString: "Couldn't get photo set from Flickr. Please try again later or try a different location.")
						}
					}
				}
			}
		}
	}
	
	// MARK: - Helpers
	
	private func photoParamsToProperties(jsonData: NSDictionary) -> [String:String]? {
		let photoId = jsonData["id"] as? String
		let secret = jsonData["secret"] as? String
		let serverId = jsonData["server"] as? String
		let farmId = jsonData["farm"] as? Int
		if photoId != nil && secret != nil && serverId != nil && farmId != nil {
			let imageSize = ImageSize.largeSquare
			let photoParams: [String:String] = [
				"photoId": photoId!,
				"secret": secret!,
				"serverId": serverId!,
				"farmId": "\(farmId!)",
				"imageSize": imageSize
			]
			let imageName = "\(photoId!)_\(secret!)_\(imageSize).jpg"
			let remotePath = self.urlKeySubstitute(Constants.photoSourceURL, kvp: photoParams)
			return [
				"imageName": imageName,
				"remotePath": remotePath
			]
		}
		return nil
	}
	
	//MARK: - Flickr expects BBox values for lat and long
	private func photoSearchGetBboxParams(latitude: Double, longitude: Double) -> String {
		let latMin = -90.0
		let latMax = 90.0
		let longMin = -180.0
		let longMax = 180.0
		
		var bBoxLatMin = latitude - bboxEdge
		var bBoxLongMin = longitude - bboxEdge
		var bBoxLatMax = latitude + bboxEdge
		var bBoxLongMax = longitude + bboxEdge
		
		if bBoxLatMax > latMax {
			bBoxLatMax = latMax
			bBoxLatMin = latMax - bboxEdge
		} else if bBoxLatMin < latMin {
			bBoxLatMin = latMin
			bBoxLatMax = latMax - bboxEdge
		}
		
		if bBoxLongMax > longMax {
			bBoxLongMax = (bBoxLongMax - longMax) + longMin
		} else if bBoxLongMin < longMin {
			bBoxLongMin = longMax - (bBoxLongMin + longMin)
		}
		
		return "\(bBoxLongMin),\(bBoxLatMin),\(bBoxLongMax),\(bBoxLatMax)"
	}
	
	private func photoSearchGetRandomPage(bboxParams: String, completionHandler: (randomPageNumber: Int?, errorString: String?) -> Void) {
		let methodParams: [String:AnyObject] = [
			"method": Methods.photosSearch,
			"bbox": bboxParams,
			"per_page": 1   // get 1 result per page as we only want the "total" figure to generate a random page number
		]
		let url = Constants.baseURL + urlParamsFromDictionary(methodParams)
		httpGet(url) { result, error in
			if error != nil {
				completionHandler(randomPageNumber: nil, errorString: error?.localizedDescription)
			} else {
				if let photos = result["photos"] as? NSDictionary {
					if let total = Int((photos["total"] as? String)!) {
						if total > 0 {
							if let randomPageNumber = self.photoSearchGetRandomPageNumber(total) {
								completionHandler(randomPageNumber: randomPageNumber, errorString: nil)
							} else {
								completionHandler(randomPageNumber: nil, errorString: "Couldn't get a random page number. Please try again later or try a different location.")
							}
						} else {
							completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
						}
					} else {
						completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
					}
				} else {
					completionHandler(randomPageNumber: nil, errorString: "Couldn't get photos from Flickr. Please try again later or try a different location.")
				}
			}
		}
	}
	
	private func photoSearchGetRandomPageNumber(totalResults: Int) -> Int? {
		let totalResults = min(totalResults, Constants.maxNumberOfResultsReturnedByFlickr)
		if totalResults <= 0 {
			return nil
		}
		
		let numberOfPages: Int
		if totalResults <= Constants.photosPerPage {
			numberOfPages = 1
		} else {
			numberOfPages = totalResults / Constants.photosPerPage
		}
		
		let randomPageNumber: Int?
		if numberOfPages > 1 {
			randomPageNumber = Int(arc4random_uniform(UInt32(numberOfPages))) + 1 // add 1 since page numbers start at 1
		} else {
			randomPageNumber = 1
		}
		return randomPageNumber
	}
	
	func urlParamsFromDictionary(parameters: [String : AnyObject]) -> String {
		var urlVars = [String]()
		var parameters = parameters
		if let additionalMethodParams = additionalMethodParams {
			for (key, value) in additionalMethodParams {
				parameters[key] = value
			}
		}
		for (key, value) in parameters {
			/* Make sure that it is a string value */
			let stringValue = "\(value)"
			
			/* Escape it */
			let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
			
			/* Append it */
			urlVars += [key + "=" + "\(escapedValue!)"]
		}
		return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
	}
	
	func httpGet(urlString: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
		if Reachability.isConnectedToNetwork() == false {
			completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.noInternet]))
			return
		}
		
		if urlString != "" {
			if let url = NSURL(string: urlString) {
				let request = NSMutableURLRequest(URL: url)
				if let additionalHTTPHeaderFields = additionalHTTPHeaderFields {
					for (httpHeaderField, value) in additionalHTTPHeaderFields {
						request.addValue(value, forHTTPHeaderField: httpHeaderField)
					}
				}
				let task = session.dataTaskWithRequest(request) { data, response, error in
					if error != nil {
						completionHandler(result: nil, error: error)
						return
					}
					self.parseJSONData(data!, completionHandler: completionHandler)
				}
				task.resume()
			} else {
				completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.invalidURL]))
			}
		} else {
			completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.emptyURL]))
		}
	}
	
	func urlKeySubstitute(method: String, kvp: [String:String]) -> String {
		var method = method
		for (key, value) in kvp {
			if method.rangeOfString("{\(key)}") != nil {
				method = method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
			}
		}
		return method
	}
	
	private func parseJSONData(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
		
		do {
			let parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
			completionHandler(result: parsedResult, error: nil)
		} catch {
			completionHandler(result: nil, error: NSError(domain: ErrorMessage.domain, code: 1, userInfo: [NSLocalizedDescriptionKey : ErrorMessage.jsonParseFailed]))
		}
	}
	
}
