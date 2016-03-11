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
		
	}

	//MARK: - outlets
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var tapPinsToDeleteNavBar: UINavigationBar!
	@IBOutlet weak var editButton: UIBarButtonItem!
	
	
	//MARK: - properties
	var inEditMode = false 
	
	//MARK: - lifecycle methods
	override func viewDidLoad() {
		super.viewDidLoad()
		mapView.delegate = self
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
			editButton.title = "Done"
		} else {
			editButton.title = "Edit"
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
	
}

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
}

