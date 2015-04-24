//
//  Album.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 16/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import CoreData

@objc(Album)

class Album: NSManagedObject {
    
    struct Keys {
        static let name = "name"
        static let location = "location"
    }
    
    // Managed variables
    @NSManaged var name: String
    @NSManaged var createdAt: NSDate
    @NSManaged var location: Location
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Album", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Set properties
        name = dictionary[Keys.name] as! String
        location = dictionary[Keys.location] as! Location
        createdAt = NSDate()
        
        // Pre-fetch photos
        Flickr.sharedInstance().preFetchPhotosForAlbum(self)
        
    }
    
    // Creates a new album pre-fetching images from the specified location
    class func createAlbumForNewLocation(location: Location, context: NSManagedObjectContext, deleteOldAlbums: Bool) {
        
        if deleteOldAlbums {
            
            // Get all albums
            let fetch = NSFetchRequest(entityName: "Album")
            fetch.predicate = NSPredicate(format:"location == %@", location)
            
            // Delete previous albums
            if let results = context.executeFetchRequest(fetch, error: nil) as? [Album] {
                
                for album in results {
                    context.deleteObject(album)
                }
            }
        }
        
        // Create a new album for the new location
        let albumDict:[String: AnyObject] = [Keys.name: "Album 1", Keys.location: location]
        let album = Album(dictionary: albumDict, context: context)
    }
}