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
	
	struct Constants {
		static let newCollection = "New Collection"
		static let delete = "Delete Selected Photos"
		static let cellIdentifier = "PhotoCell"
		static let noPhoto = "noPhoto.png"
	}
	
	//MARK: properties
	
	var pin: Pin!
	
	// The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is used inside cellForItemAtIndexPath to lower the
	//alpha of selected cells.
	var selectedIndexes = [NSIndexPath]()
	var insertedIndexPaths: [NSIndexPath]!
	var deletedIndexPaths: [NSIndexPath]!
	var updatedIndexPaths: [NSIndexPath]!
	var noPhotosDownloading = 0
	
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
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var noImagesFound: UILabel!
	
	//MARK: lifecycle methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setToolbarButtonTitle()
		collectionView.allowsMultipleSelection = true
		fetchedResultsController.delegate = self
		activityIndicator.hidesWhenStopped = true
		activityIndicator.stopAnimating()
		noImagesFound.hidden = true
		
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
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Lay out the collection view so that cells take up 1/3 of the width
		let width = CGRectGetWidth(view.frame) / 3
		let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width, height: width) //want them to be square
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//initialize map view
		mapView.userInteractionEnabled = false
		
		if let pin = pin {
			let pinLocation = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100000, 100000)
			mapView.setRegion(pinLocation, animated: false)
			mapView.addAnnotation(pin)
		}
		
		toolbarEnabledState()
	}
	
	//MARK: download photo properties (photo id and url_m string) from the server.
	
	func downloadPhotoProperties() {
		activityIndicator.startAnimating()
		
		if pin.fetchInProgress == true {
			return
		} else {
			pin.fetchInProgress = true
		}
		
		FlickrClient.sharedInstance.downloadPhotoProperties(pin) { (data, error) -> Void in
			
			guard error == nil else {
				print("error in downloading photo properties")
				self.activityIndicator.stopAnimating()
				self.toolBarButton.enabled = true
				self.noImagesFound.hidden = false
				return
			}
			
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
			self.pin.fetchInProgress = false
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
	
	func deleteSelectedPhotos() {
		var photosToDelete = [Photo]()
		for indexPath in selectedIndexes {
			photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
		}
		for photo in photosToDelete {
			sharedContext.deleteObject(photo)
		}
		CoreDataStackManager.sharedInstance.saveContext()
		
		selectedIndexes = [NSIndexPath]()
		setToolbarButtonTitle()
		toolbarEnabledState()
	}
	
	func createNewPhotoCollection() {
		if let fetchedObjects = fetchedResultsController.fetchedObjects {
			for object in fetchedObjects {
				let photo = object as! Photo
				sharedContext.deleteObject(photo)
			}
			CoreDataStackManager.sharedInstance.saveContext()
		}
		downloadPhotoProperties()
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
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.cellIdentifier, forIndexPath: indexPath) as! PhotoCell
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
			cell.flickrImage.image = UIImage(named: Constants.noPhoto)
			cell.activityIndicator.startAnimating()
			
			if photo.fetchInProgress == false {
				noPhotosDownloading++
				photo.fetchImageData(photo.imageURL, completionHandler: { (fetchComplete, error) -> Void in
					self.noPhotosDownloading--
					if fetchComplete == true {
						self.performUIUpdatesOnMain({ () -> Void in
							self.collectionView.reloadItemsAtIndexPaths([indexPath])
						})
					}
				})
			}
		}
		
		toolbarEnabledState()
		
		if let _ = selectedIndexes.indexOf(indexPath) {
			cell.selectedColor.alpha = 0.8
		} else {
			cell.selectedColor.alpha = 0.0
		}
	}
	
	//MARK: collection view delegate methods
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
		
		selectedIndexes.append(indexPath)
		
		configureCell(cell, atIndexPath: indexPath)
		setToolbarButtonTitle()
		toolbarEnabledState()
	}
	
	func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
		let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
		
		if let index = selectedIndexes.indexOf(indexPath) {
			selectedIndexes.removeAtIndex(index)
		}
		configureCell(cell, atIndexPath: indexPath)
		setToolbarButtonTitle()
		toolbarEnabledState()
	}
	
	// MARK: - NSFetchedResultsController delegates
	
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		insertedIndexPaths = [NSIndexPath]()
		deletedIndexPaths = [NSIndexPath]()
		updatedIndexPaths = [NSIndexPath]()
		
		self.activityIndicator.stopAnimating()
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
	
	private func setToolbarButtonTitle() {
		if selectedIndexes.count > 0 {
			toolBarButton.title = Constants.delete
		} else {
			toolBarButton.title = Constants.newCollection
		}
	}
	
	private func toolbarEnabledState() {
		if toolBarButton.title == Constants.newCollection {
			if pin.fetchInProgress == true || noPhotosDownloading > 0 {
				toolBarButton.enabled = false
			} else {
				toolBarButton.enabled = true
			}
		} else {
			toolBarButton.enabled = true
		}
	}
}

