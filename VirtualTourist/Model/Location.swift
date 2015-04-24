//
//  Location.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 16/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation
import CoreData

@objc(Location)

class Location: NSManagedObject {
    
    enum LocationContext {
        case Pending, Empty, Fetched, Failed
    }
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let name = "name"
    }
    
    // Managed variables
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var name: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
        name = dictionary[Keys.name] as! String
        
        // Create a default album
        Album.createAlbumForNewLocation(self, context: context, deleteOldAlbums: false)
    
    }
    
    // This variable specify if after pre-fetching the set of images is pending, empty, fetched or failed
    var content: LocationContext = LocationContext.Pending {
        didSet {
            // When the content is pending, create a new album and start pre-fetching
            if content  == LocationContext.Pending {
                Album.createAlbumForNewLocation(self, context: self.managedObjectContext!, deleteOldAlbums: true)
            }
        }
    }
    
    
}