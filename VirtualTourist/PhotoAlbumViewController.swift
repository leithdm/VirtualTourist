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
	
	
	var pin: Pin!
	var photos = [Photo]() //dummy array for testing. This should really be assigned to each pin
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		//MARK: initialize map view
		mapView.delegate = self
		mapView.userInteractionEnabled = false
		
		if let pin = pin {
			let pinLocation = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100000, 100000)
			mapView.setRegion(pinLocation, animated: false)
			mapView.addAnnotation(pin)
		}
		
		//MARK: initialize collection view
		let width = CGRectGetWidth(view.frame) / 3
		let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width, height: width) //want them to be square
		
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if photos.isEmpty {
			downloadPhotosFromServer()
		}
	}
	
	//MARK: download flickr photos from the server
	
	private func downloadPhotosFromServer() {
		FlickrClient.sharedInstance.searchForPhotos(pin) { (data, error) -> Void in
			if let data = data {
				
				_ = data.map({ (dictionary: [String: AnyObject]) -> Photo in
					let photo = Photo(dictionary: dictionary)
					photo.pin = self.pin
					self.photos.append(photo)
					return photo
				})
				
				self.performUIUpdatesOnMain({ () -> Void in
					self.collectionView.reloadData()
				})
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
		let photo = photos[indexPath.item]
		var photoImage = UIImage(named: "icon.gif")

		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICustomCollectionViewCell", forIndexPath: indexPath) as! UICustomCollectionViewCell
		
		cell.activityIndicator.startAnimating()
		cell.flickrImage.image = nil
		
		if photo.image != nil {
			photoImage = photo.image
			cell.activityIndicator.stopAnimating()
		}
		else { //download data from....???
			print("i got to here")
			let task = FlickrClient.sharedInstance.taskForImage(photo.imageId, completionHandler: { (imageData, error) -> Void in
				if let data = imageData {
					let image = UIImage(data: data)
					photo.image = image
					
					self.performUIUpdatesOnMain({ () -> Void in
						cell.flickrImage.image = image
						cell.activityIndicator.stopAnimating()
					})
				}
			})
			cell.taskToCancelifCellIsReused = task
		}
		cell.flickrImage.image = photoImage
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
