//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	
	var pin: Pin!
    private var selectedIndexes = [NSIndexPath]()
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var toolBarButton: UIBarButtonItem!
	@IBOutlet weak var toolBar: UIToolbar!
	
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
		
		initializeCollectionView()
	}

	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if pin.photos.isEmpty {
			downloadPhotoProperties()
		}
	}
	
	//MARK: download photo properties (photo id and url_m string) from the server. 
	
	private func downloadPhotoProperties() {
		
//		if pin.fetchInProgress == true {
//			return
//		} else {
//			pin.fetchInProgress = true
//		}
		
		FlickrClient.sharedInstance.downloadPhotoProperties(pin) { (data, error) -> Void in
			if let data = data {
				_ = data.map({ (dictionary: [String: AnyObject]) -> Photo in
					let photo = Photo(dictionary: dictionary, context: self.sharedContext)
					photo.pin = self.pin
					return photo
				})
				
				self.performUIUpdatesOnMain({ () -> Void in
					self.collectionView.reloadData()
					CoreDataStackManager.sharedInstance.saveContext()
				})
			}
//			self.pin.fetchInProgress = false
		}
	}
	
	//MARK: core data
	
	lazy var sharedContext: NSManagedObjectContext = {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	
	//MARK: collection view datasource methods
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pin.photos.count
	}
	
	@IBAction func toolBarDelete(sender: UIBarButtonItem) {
			if selectedIndexes.count > 0 {
				deleteSelectedPhotos()
			} else {
				createNewPhotoCollection()
			}
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let photo = pin.photos[indexPath.item]
		var photoImage = UIImage(named: "noPhoto.png")

		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICustomCollectionViewCell", forIndexPath: indexPath) as! UICustomCollectionViewCell
		
		cell.setUpActivityIndicator(cell)
		cell.activityIndicator.startAnimating()

		cell.flickrImage.image = nil
		
		if photo.image != nil { //the image has already been downloaded and is in the Documents directory
			photoImage = photo.image
			cell.activityIndicator.stopAnimating()
		}
		else {
			//download the image from the remote server
			let task = FlickrClient.sharedInstance.taskForDownloadingImage(photo.imageURL, completionHandler: { (imageData, error) -> Void in
				if let data = imageData {
					let image = UIImage(data: data)
					photo.image = image //gets cached to the docs directory using setter
					
					//update the cell
					self.performUIUpdatesOnMain({ () -> Void in
						cell.flickrImage.image = image
						cell.activityIndicator.stopAnimating()
						collectionView.reloadData()
					})
				}
			})
			
			//property observer - any time a value is set it cancels the previous NSURLSessionTask
			cell.taskToCancelifCellIsReused = task
		}
		cell.flickrImage.image = photoImage
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let photo = pin.photos[indexPath.item]
		photo.pin = nil
		collectionView.deleteItemsAtIndexPaths([indexPath])
		sharedContext.deleteObject(photo)
		removeFromDocumentsDirectory(photo.imageId)
		CoreDataStackManager.sharedInstance.saveContext()
//		setToolbarButtonTitle()
//		displayToolbarEnabledState()
	}
	
	func removeFromDocumentsDirectory(identifier: String) {
		let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
		let path = fullURL.path!
		
		do {
		try NSFileManager.defaultManager().removeItemAtPath(path)
		} catch {
			//
		}
	}
	
	//MARK: create/delete photos collection
	
	private func createNewPhotoCollection() {
		//TODO: update for CoreData
		pin.photos.removeAll(keepCapacity: true)
		downloadPhotoProperties()
	}
	
	private func deleteSelectedPhotos() {
		for indexPath in selectedIndexes {
			pin.photos.removeAtIndex(indexPath.item)
		}
		collectionView.reloadData()
//		setToolbarButtonTitle()
//		displayToolbarEnabledState()
	}
	
	//MARK: helper methods
	
	func performUIUpdatesOnMain(updates: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			updates()
		}
	}
	
	//MARK: initialize collection view
	
	func initializeCollectionView() {
		//MARK: initialize collection view
		let width = CGRectGetWidth(view.frame) / 3
		let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width, height: width) //want them to be square
	}
	
}


extension PhotoAlbumViewController: MKMapViewDelegate {
	
}
