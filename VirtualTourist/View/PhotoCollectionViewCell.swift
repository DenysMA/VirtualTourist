//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 18/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//  Custom Cell to represent a photo in the CollectionView

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
 
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

}
