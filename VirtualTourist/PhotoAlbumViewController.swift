//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Darren Leith on 11/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {

	//MARK: - properties
	
	var pinSelection: Pin?
	
	//MARK: - outlets
	
	@IBOutlet weak var mapView: MKMapView!
	
	
	//MARK: - lifecycle methods
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		mapView.delegate = self
		
		if let pinSelection = pinSelection {
			print("we have a pin.\(pinSelection.latitude) \(pinSelection.longitude)")
		}
    }
	
	
}

extension PhotoAlbumViewController: MKMapViewDelegate {
	
}
