//
//  FlirckConstants.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 18/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation

extension Flickr {
    
    // MARK: - Constants
    struct Constants {
        
        // MARK: URLs
        static let baseURL : String = "https://api.flickr.com/services/rest/"
        static let apiKey : String = "567fed0a53d49c808342bb39837274aa"
        static let resultsPerPage = 20
        static let extras = "url_m"
        static let safeSearch = "1"
        static let dataFormat = "json"
        static let no_json_callback = "1"
        static let defaultPage = 1
    }
    
    // MARK: - Methods
    struct Methods {
        
        // MARK: Account
        static let PhotoSearch = "flickr.photos.search"
    }
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
        
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let SafeSearch = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let JSONCallBack = "nojsoncallback"
        static let resultsPerPage = "per_page"
        static let pageNumber = "page"
        
    }
    
    // MARK: - JSON Response Keys
    struct JSONResponseKeys {
        
        // MARK: General
        static let ErrorMessage = "message"
        static let Status = "stat"
        static let ErrorCode = "code"
        
    }
    
}