//
//  FlickrManagedContext.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 23/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import CoreData

extension Flickr {
    
    // MARK: - Pre-fetch Photos
    
    func preFetchPhotosForAlbum(album: Album) {
        
        // Get context
        let sharedContext = album.managedObjectContext!
        
        // Start request
        getImageFromFlickrByLatLon(album.location.latitude, longitude: album.location.longitude, page: Constants.defaultPage) { results, error in
            
            // If error then update location content
            if let error = error {
                
                album.location.content = Location.LocationContext.Failed
                println("Error pre-fetching images \(error.debugDescription)")
                
            }
            else {
                
                // If there are some results, then add photo objects into the context
                if let results = results {
                    
                    for photo in results {
                        
                        var photo = photo
                        photo["album"] = album
                        let newphoto = Photo(dictionary: photo, context: sharedContext)
                    }
                    
                    // Update location content
                    album.location.content = Location.LocationContext.Fetched
                }
                
                // When no results then update location content to Empty
                else {
                    
                    album.location.content = Location.LocationContext.Empty
                    println("No photos found for this location")
                }
            }
        }
    }
    
}