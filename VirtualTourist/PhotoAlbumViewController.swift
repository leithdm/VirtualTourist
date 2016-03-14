//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource {
	
	
	var pinSelection: Pin!
	var photos: [Photo] = []
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		//MARK: initialize map view
		mapView.delegate = self
		mapView.userInteractionEnabled = false
		
		if let pinSelection = pinSelection {
			let pinLocation = MKCoordinateRegionMakeWithDistance(pinSelection.coordinate, 100000, 100000)
			mapView.setRegion(pinLocation, animated: false)
			mapView.addAnnotation(pinSelection)
		}
		
		//MARK: initialize collection view
		let width = CGRectGetWidth(view.frame) / 3
		let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width, height: width) //want them to be square
		
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		getFlickrPhotos()
	}
	
	private func getFlickrPhotos() {
		
		FlickrClient.sharedInstancde.searchForPhotos(pinSelection) { (data, error) -> Void in
			if let data = data {
				for (_, value) in data.enumerate() {
					
					
					// GUARD: Does our photo have a key for 'url_m'? */
					guard let imageUrlString = value[FlickrClient.FlickrResponseKeys.MediumURL] as? String,
						let imageTitle = value[FlickrClient.FlickrResponseKeys.Title] as? String else {
							return
					}
//					print(imageUrlString)
//					print(imageTitle)
					
					let photo = Photo(imageName: imageTitle, remotePath: imageUrlString)
					photo.image = UIImage(data: NSData(contentsOfURL: NSURL(string: imageUrlString)!)!)
					self.photos.append(photo)
					
					self.performUIUpdatesOnMain({ () -> Void in
						self.collectionView.reloadData()
					})
					
				}
			}
		}
		
	}
	
	//MARK: collection view datasource methods
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photos.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let photo = photos[indexPath.row]
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICustomCollectionViewCell", forIndexPath: indexPath) as! UICustomCollectionViewCell
		
		if let localImage = photo.image {
			cell.flickrImage.image = localImage
		} else if photo.remotePath == "" {
			cell.flickrImage.image = UIImage(named: "icon")
		}
			// If the above cases don't work, then we should download the image
		else {
			cell.flickrImage.image = UIImage(named: "icon")
			let photoURL = NSURL(string: photo.remotePath)!
			performUIUpdatesOnMain({ () -> Void in
				cell.flickrImage.image = UIImage(data: NSData(contentsOfURL: photoURL)!)
			})
			
		}
		return cell
	}
	
	//MARK: helper methods
	
	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
}


extension PhotoAlbumViewController: MKMapViewDelegate {
	
}
