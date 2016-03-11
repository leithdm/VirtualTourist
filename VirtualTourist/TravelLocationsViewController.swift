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

	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var tapPinsToDeleteNavBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addLongPressPinDropRecognizer()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tapPinsToDeleteNavBar.alpha = 0.0
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
		print(pinCoordinates.latitude, pinCoordinates.longitude)
			
			
		let pin = Pin(latitude: pinCoordinates.latitude, longitude: pinCoordinates.longitude)
		mapView.addAnnotation(pin)
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

}

