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
	}

	//MARK: - outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var tapPinsToDeleteNavBar: UINavigationBar!
	@IBOutlet weak var editButton: UIBarButtonItem!
	
	
	//MARK: - properties
	var inEditMode = false
	var pinSelection: Pin?
	
	
	var filePath : String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
		return url.URLByAppendingPathComponent("mapRegionArchive").path!
	}

	
	//MARK: - lifecycle methods
	override func viewDidLoad() {
		super.viewDidLoad()
		mapView.delegate = self
		restoreMapRegion(true)
		
		navigationItem.backBarButtonItem = UIBarButtonItem(title: Constants.backButtonOK, style: .Plain, target: nil, action: nil)
		addLongPressPinDropRecognizer()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tapPinsToDeleteNavBar.hidden = true
	}

	
	//MARK: - gesture recognizer
	
	func addLongPressPinDropRecognizer() {
		let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropAPin:")
		view.addGestureRecognizer(longPressGestureRecognizer)
	}
	
	//MARK: - drop a pin
	
	func dropAPin(pinDropRecognizer: UIGestureRecognizer) {
		if pinDropRecognizer.state == .Began {
		let locationInView = pinDropRecognizer.locationInView(mapView)
		let pinCoordinates = mapView.convertPoint(locationInView, toCoordinateFromView: mapView)
		let pin = Pin(latitude: pinCoordinates.latitude, longitude: pinCoordinates.longitude)
		mapView.addAnnotation(pin)
		}
	}
	
	//MARK: - in edit mode
	
	@IBAction func didSelectEditMode(sender: UIBarButtonItem) {
		editing = editing == true ? false: true
		
		if editing {
			editButton.title = Constants.editButtonDone
		} else {
			editButton.title = Constants.editButtonEdit
		}
		statusTapPinDeleteNavBar()
		statusEditButtonEnabled()
	}
	
	//helper functions
	func statusTapPinDeleteNavBar() {
		if editing {
			tapPinsToDeleteNavBar.hidden = false
		} else {
			tapPinsToDeleteNavBar.hidden = true
		}
	}
	
	func statusEditButtonEnabled() {
		//TODO: -
	}
	
	//MARK: - prepare for segue
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "PhotoAlbumViewController" {
		let pavc = segue.destinationViewController as! PhotoAlbumViewController
		pavc.pin = pinSelection
		}
	}
	
	//MARK: save map state
	
	func saveMapRegion() {
		let dictionary = [
			"latitude" : mapView.region.center.latitude,
			"longitude" : mapView.region.center.longitude,
			"latitudeDelta" : mapView.region.span.latitudeDelta,
			"longitudeDelta" : mapView.region.span.longitudeDelta
		]
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
	
	func restoreMapRegion(animated: Bool) {
		// if we can unarchive a dictionary, we will use it to set the map back to its previous center and span
		if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
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
			pinView!.animatesDrop = true
			pinView!.draggable = true
			pinView!.pinTintColor = UIColor.purpleColor()
		}
		else {
			pinView!.annotation = annotation
		}
		return pinView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		let pin = view.annotation as! Pin
		pinSelection = pin
		performSegueWithIdentifier("PhotoAlbumViewController", sender: self)
	}
	
	//any time map is moved save the map state
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		saveMapRegion()
	}
}

