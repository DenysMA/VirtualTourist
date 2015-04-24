//
//  Photo.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 16/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    enum PhotoState: Int {
        case New = 0, Downloaded, Failed
    }
    
    // Managed variables
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var imagePath: String
    @NSManaged var state: Int
    @NSManaged var album: Album
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    
        // Set image if exist
        if let image = Flickr.Caches.imageCache.imageWithIdentifier(imagePath) {
            photoImage = image
            state = PhotoState.Downloaded.rawValue
        }
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // dictionary
        id = dictionary["id"] as! String
        name = dictionary["title"] as! String
        imagePath = dictionary["url_m"] as! String
        album = dictionary["album"] as! Album
        
        if let image = Flickr.Caches.imageCache.imageWithIdentifier(imagePath) {
            photoImage = image
            state = PhotoState.Downloaded.rawValue
        }
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        // Get number of photos store for all locations and albums with this identifier
        let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        let fetch = NSFetchRequest(entityName: "Photo")
        let predicate = NSPredicate(format:"id == %@", self.id)
        fetch.predicate = predicate
        
        // Discard pending changes to include this instance in the query
        fetch.includesPendingChanges = false
        
        // Get number of results
        let results = sharedContext?.countForFetchRequest(fetch, error: nil)
        
        // Check if this photo id only exist for this album, then delete photo from documents dir and cache
        if results <= 1 {
                
            Flickr.Caches.imageCache.storeImage(nil, withIdentifier: imagePath)
        }
    }
    
    var photoImage: UIImage? = nil {
        
        // Store image in cache and documents dir after it is downloaded
        didSet {
            
            // Image is valid then update state to downloaded
            if photoImage != nil {
                
                Flickr.Caches.imageCache.storeImage(photoImage, withIdentifier: imagePath)
                state = PhotoState.Downloaded.rawValue
            }
            else {
                
                // Image is invalid then update state to new or pending for dowloading
                state = PhotoState.New.rawValue
            }
        }
    }

    
}

