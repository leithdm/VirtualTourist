//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController {
	
	//MARK: - constants
	
	struct Constants {
		static let pinReuseId = "pin"
		static let editButtonDone = "Done"
		static let editButtonEdit = "Edit"
		static let backButtonOK = "OK"
		static let segue = "PhotoAlbumViewController"
	}
	
	//MARK: - outlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var editButton: UIBarButtonItem!
	@IBOutlet weak var deleteToolBar: UIToolbar!
	
	//MARK: - properties
	
	var inEditMode = false
	var selectedPin: Pin? = nil
	var dragPinEnded = false
	var longPressGestureRecognizer: UILongPressGestureRecognizer!
	
	//file path for saving the map state - long/lat/span
	var mapStateFilePath : String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
		return url.URLByAppendingPathComponent("mapState").path!
	}
	
	
	private func displayToolbarHiddenState() {
		if inEditMode == true {
			deleteToolBar.hidden = false
		} else {
			deleteToolBar.hidden = true
		}
	}
	
	//MARK: - lifecycle methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		mapView.delegate = self
		navigationItem.backBarButtonItem = UIBarButtonItem(title: Constants.backButtonOK, style: .Plain, target: nil, action: nil)
		restoreMapState(true)
		addLongPressPinDropRecognizer()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        displayToolbarHiddenState()
		selectedPin = nil
	}
	
	
	//MARK: - gesture recognizer
	
	func addLongPressPinDropRecognizer() {
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPin:")
		longPressGestureRecognizer.minimumPressDuration = 0.4
		view.addGestureRecognizer(longPressGestureRecognizer)
	}
	
	//MARK: - drop a pin
	
	func dropPin(pinDropRecognizer: UIGestureRecognizer) {
		//this prevents multiple pins from being dropped
		if pinDropRecognizer.state != UIGestureRecognizerState.Began {
			return
		}
		
		let locationInView = pinDropRecognizer.locationInView(mapView)
		let pinCoordinates = mapView.convertPoint(locationInView, toCoordinateFromView: mapView)
		let pin = Pin(latitude: pinCoordinates.latitude, longitude: pinCoordinates.longitude)
		mapView.addAnnotation(pin)
		displayEditButton()
		
		//TODO: pre-fetch
		fetchFlickrPhotoProperties(pin)
	}
	
	
	// Pre-fetch photo data from Flickr as soon as a pin is dropped
	func fetchFlickrPhotoProperties(pin: Pin) {
		FlickrClient.sharedInstance.downloadPhotoProperties(pin, completionHandler: { (data, error) -> Void in
			if let photoProperties = data {
				for photoProperty in photoProperties {
					let photo = Photo(dictionary: photoProperty)
					photo.pin = pin
				}
			}
		})
	}
	
	
	//MARK: - in edit mode
	
	@IBAction func didSelectEditMode(sender: UIBarButtonItem) {
		editing = editing == true ? false: true
		
		if editing == true {
			editButton.title = Constants.editButtonDone
			removeDropPinGestureRecognizer()
		} else {
			editButton.title = Constants.editButtonEdit
			addLongPressPinDropRecognizer()
		}
		displayDeleteToolBar()
		displayEditButton()
	}
	
	func removeDropPinGestureRecognizer() {
		view.removeGestureRecognizer(longPressGestureRecognizer)
	}
	
	//helper functions
	func displayDeleteToolBar() {
		if editing == true {
			deleteToolBar.hidden = false
		} else {
			deleteToolBar.hidden = true
		}
	}
	
	func displayEditButton() {
		editButton.enabled = true
	}
	
	func deletePin(pin: Pin) {
		mapView.removeAnnotation(pin)
	}
	
	
	//MARK: - prepare for segue
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "PhotoAlbumViewController" {
			let pavc = segue.destinationViewController as! PhotoAlbumViewController
			pavc.pin = selectedPin
		}
	}
	
	//MARK: save and restore map state
	
	func saveMapState() {
		let dictionary = [
			"latitude" : mapView.region.center.latitude,
			"longitude" : mapView.region.center.longitude,
			"latitudeDelta" : mapView.region.span.latitudeDelta,
			"longitudeDelta" : mapView.region.span.longitudeDelta
		]
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: mapStateFilePath)
	}
	
	func restoreMapState(animated: Bool) {
		if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapStateFilePath) as? [String : AnyObject] {
			let longitude = regionDictionary["longitude"] as! CLLocationDegrees
			let latitude = regionDictionary["latitude"] as! CLLocationDegrees
			let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
			let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
			let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
			
			let savedRegion = MKCoordinateRegion(center: center, span: span)
			mapView.setRegion(savedRegion, animated: animated)
		}
	}
}

//MARK: - MKMapView delegate methods

extension TravelLocationsViewController: MKMapViewDelegate {
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.pinReuseId) as? MKPinAnnotationView
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.pinReuseId)
		} 	else {
			pinView!.annotation = annotation
		}
		
		pinView!.draggable = true
		pinView!.animatesDrop = true
		pinView!.pinTintColor = UIColor.purpleColor()
		pinView!.setSelected(true, animated: true)
		return pinView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		
		mapView.deselectAnnotation(view.annotation, animated: false)
		view.setSelected(true, animated: true)
		
		let pin = view.annotation as! Pin
		
		if dragPinEnded == true {
			//TODO: method to update the pin for new location
			dragPinEnded = false
			return
		}
		
		if editing == true {
			deletePin(pin)
		} else {
			selectedPin = pin
			performSegueWithIdentifier(Constants.segue, sender: self)
		}
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		
		// track the immediate result of an .Ending pin drag state
		if newState == MKAnnotationViewDragState.Ending {
			dragPinEnded = true
		}
	}
	
	//any time map is moved save the map state
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		saveMapState()
	}
	
	
}

