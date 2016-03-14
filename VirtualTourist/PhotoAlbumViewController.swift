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
//		activityIndicator.startAnimating()
		
//		if pinSelection.photoPropertiesFetchInProgress == true {
//			return
//		} else {
//			pinSelection.photoPropertiesFetchInProgress = true
//		}
		
//		noImagesFoundLabel.hidden = true
//		toolbarButton.enabled = false
		
		FlickrClient.sharedInstancde.searchForPhotos(pinSelection) { (data, error) -> Void in
			if let data = data {
				for (_, value) in data.enumerate() {
				
	
					// GUARD: Does our photo have a key for 'url_m'? */
					guard let imageUrlString = value[FlickrClient.FlickrResponseKeys.MediumURL] as? String,
						let imageTitle = value[FlickrClient.FlickrResponseKeys.Title] as? String else {
						return
					}
					
					print(imageUrlString)
					print(imageTitle)
					
					let photo = Photo(remotePath: imageUrlString)
					self.photos.append(photo)
					
//					let photo = Photo(imageName: value[imageTitle] as! String, remotePath: value[imageUrlString] as! String)
//					print(photo.imageName)
				}
			}
			self.performUIUpdatesOnMain({ () -> Void in
				self.collectionView.reloadData()
			})
		}
		
		
		/*
		FlickrClient.sharedInstance.photosSearch(pinSelection!) { photoProperties, errorString in
			if errorString != nil {
				dispatch_async(dispatch_get_main_queue()) {
//					self.activityIndicator.stopAnimating()
//					self.toolbarButton.enabled = true
//					self.noImagesFoundLabel.hidden = false
				}
			} else {
				if let photoProperties = photoProperties {
					for photoProperty in photoProperties {
						let photo = Photo(imageName: photoProperty["imageName"]!, remotePath: photoProperty["remotePath"]!)
						print(photo.imageName)
						photo.pin = self.pinSelection
					}

				}
			}
		}
*/
	}
	
	//MARK: - collection view
	
	
		
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
			return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photos.count
	}
		
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICustomCollectionViewCell", forIndexPath: indexPath) as! UICustomCollectionViewCell
		
		let photo = photos[indexPath.row]
		let photoURL = NSURL(string: photo.remotePath)!

		cell.flickrImage.image = UIImage(data: NSData(contentsOfURL: photoURL)!)
		return cell
	}

	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
	
 }


extension PhotoAlbumViewController: MKMapViewDelegate {
	
}
