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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
	
	//MARK: properties
	
	var pin: Pin!

	// The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is used inside cellForItemAtIndexPath to lower the
	//alpha of selected cells.  You can see how the array works by searchign through the code for 'selectedIndexes'
	var selectedIndexes = [NSIndexPath]()
	var insertedIndexPaths: [NSIndexPath]!
	var deletedIndexPaths: [NSIndexPath]!
	var updatedIndexPaths: [NSIndexPath]!
	
	//fetchedResultsController
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageId", ascending: true)]

		
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		return fetchedResultsController
	}()
	
	lazy var sharedContext: NSManagedObjectContext = {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	
	//MARK: outlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var toolBarButton: UIBarButtonItem!
	@IBOutlet weak var toolBar: UIToolbar!
	
	
	//MARK: lifecycle methods
	override func viewDidLoad() {
		super.viewDidLoad()
	
		
		initializeCollectionView()
		
		fetchedResultsController.delegate = self
		//start the fetch
		do {
			try fetchedResultsController.performFetch()
		} catch let error as NSError  {
			print("Error performing NSFetchedResultsController fetch: \(error)")
		}
		
		if pin.photos.isEmpty {
			downloadPhotoProperties()
		}
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	
		//initialize map view
		mapView.delegate = self
		mapView.userInteractionEnabled = false
		
		if let pin = pin {
			let pinLocation = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100000, 100000)
			mapView.setRegion(pinLocation, animated: false)
			mapView.addAnnotation(pin)
		}
	}
	
	//MARK: download photo properties (photo id and url_m string) from the server.
	
	 func downloadPhotoProperties() {
		
		FlickrClient.sharedInstance.downloadPhotoProperties(pin) { (data, error) -> Void in
			if let data = data {
				_ = data.map({ (dictionary: [String: AnyObject]) -> Photo in
					let photo = Photo(dictionary: dictionary, context: self.sharedContext)
					photo.pin = self.pin
					return photo
				})
				
				self.performUIUpdatesOnMain({ () -> Void in
					CoreDataStackManager.sharedInstance.saveContext()
				})
			}
			//self.pin.fetchInProgress = false
		}
	}
	
	//MARK: delete photos
	
	@IBAction func toolBarDelete(sender: UIBarButtonItem) {
		if selectedIndexes.count > 0 {
			deleteSelectedPhotos()
		} else {
			createNewPhotoCollection()
		}
	}
	
	
	//MARK: collection view datasource methods
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
//		return self.fetchedResultsController.sections?.count ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let sectionInfo = fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
		configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	
	func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
		let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		cell.setUpActivityIndicator(cell)
		
		//the image has already been downloaded and is in the Documents directory
		if let image = photo.image {
			cell.activityIndicator.stopAnimating()
			cell.flickrImage.image = image
		}
		else { //download the image from the remote server
			cell.flickrImage.image = UIImage(named: "noPhoto.png")
			cell.activityIndicator.startAnimating()
			
			photo.fetchImageData(photo.imageURL, completionHandler: { (fetchComplete, error) -> Void in
				if fetchComplete ==  true {
					self.performUIUpdatesOnMain({ () -> Void in
						self.collectionView.reloadItemsAtIndexPaths([indexPath])
					})
				}
			})
		}
	}
	
	//MARK: collection view delegate methods
	
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
	
	func createNewPhotoCollection() {
		
		//Empty the current array of photos.
		for photo in pin.photos {
			photo.pin = nil
			sharedContext.deleteObject(photo)
			removeFromDocumentsDirectory(photo.imageId)
		}
		
		collectionView.reloadData()
		
		//Download a new set of photos.
		downloadPhotoProperties()
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	func deleteSelectedPhotos() {
		for indexPath in selectedIndexes {
			pin.photos.removeAtIndex(indexPath.item)
		}
		collectionView.reloadData()
		//		setToolbarButtonTitle()
		//		displayToolbarEnabledState()
	}
	
	// MARK: - NSFetchedResultsController delegates
	
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		insertedIndexPaths = [NSIndexPath]()
		deletedIndexPaths = [NSIndexPath]()
		updatedIndexPaths = [NSIndexPath]()
		
		//TODO: activity indicator
		//self.activityIndicator.stopAnimating()
	}
	
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Insert:
			insertedIndexPaths.append(newIndexPath!)
		case .Delete:
			deletedIndexPaths.append(indexPath!)
		case .Update:
			updatedIndexPaths.append(indexPath!)
		default:
			return
		}
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		collectionView.performBatchUpdates({
			for indexPath in self.insertedIndexPaths {
				self.collectionView.insertItemsAtIndexPaths([indexPath])
			}
			for indexPath in self.deletedIndexPaths {
				self.collectionView.deleteItemsAtIndexPaths([indexPath])
			}
			for indexPath in self.updatedIndexPaths {
				self.collectionView.reloadItemsAtIndexPaths([indexPath])
			}
			}, completion: nil)
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
