//
//  ImageDownloader.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 22/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit

// MARK : Image Downloader operation

class ImageDownloader: NSOperation {
    
    // Declare photo property
    let photoRecord: Photo
    
    // Initializer with Photo object
    init(photoRecord: Photo) {
        self.photoRecord = photoRecord
    }
    
    // Work to perform by the operation
    override func main() {
        
        // Check if operation is cancelled
        if self.cancelled {
            return
        }
        
        // Start downloading image
        let imageData = NSData(contentsOfURL:NSURL(string: self.photoRecord.imagePath)!)
        
        // Check if operation was cancelled before setting the image
        if self.cancelled {
            return
        }

        // If image data is valid then set image to photoImageProperty. (This will cause the image to be stored and it will update Photo.state property)
        if imageData?.length > 0 {
            self.photoRecord.photoImage = UIImage(data:imageData!)
        }
        else
        {
            // If the image data is invalid then update state property to Failed
            self.photoRecord.state = Photo.PhotoState.Failed.rawValue
        }
    }
}

// MARK : Pending Operations

class PendingOperations {
    
    // Create a dictionary to keep track of the downloads or operations in execution
    lazy var downloadsInProgress = [NSIndexPath:NSOperation]()
    
    // Create a queue to process all the downloads
    lazy var downloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download Image queue"
        return queue
        }()
}