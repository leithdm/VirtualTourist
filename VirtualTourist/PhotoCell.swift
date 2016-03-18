//
//  UICustomCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Darren Leith on 14/03/2016.
//  Copyright © 2016 Darren Leith. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
	
	@IBOutlet weak var flickrImage: UIImageView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	var imageName: String = ""
	@IBOutlet weak var selectedColor: UIView!

	//initialize the activity indicator
	func setUpActivityIndicator(cell: PhotoCell) {
		cell.activityIndicator.hidesWhenStopped = true
		cell.activityIndicator.activityIndicatorViewStyle = .WhiteLarge
	}
}
