//
//  Flirck.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 18/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import Foundation

class Flickr: Client {
    
    // Returns a single instance of flirck client
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr(baseUrlString : Constants.baseURL)
        }
        
        return Singleton.sharedInstance
    }
    
    // Last Search status info of the last query
    struct Status {
        
        static var lastLatitude : Double = 0
        static var lastLongitude : Double = 0
        static var lastPage : Int = 0
        static var numberOfPages : Int = 0
        static var hasMorePages : Bool = false
        static var executed : Bool = false
    }
    
    // MARK: - Get Photos by Location
    
    func getImageFromFlickrByLatLon(latitude: Double, longitude: Double, page: Int, completionHandler: (results: [[String: AnyObject]]?, error: String?) -> Void) -> NSURLSessionDataTask {
        
        let method = ""
        
        let parameters: [String : AnyObject] = [
            ParameterKeys.Method : Methods.PhotoSearch,
            ParameterKeys.ApiKey : Constants.apiKey,
            ParameterKeys.Latitude : latitude,
            ParameterKeys.Longitude : longitude,
            ParameterKeys.SafeSearch : Constants.safeSearch,
            ParameterKeys.Extras : Constants.extras,
            ParameterKeys.Format : Constants.dataFormat,
            ParameterKeys.JSONCallBack : Constants.no_json_callback,
            ParameterKeys.resultsPerPage : Constants.resultsPerPage,
            ParameterKeys.pageNumber : page
        ]
        
        return taskForGETMethod(method, parameters: parameters, headers: [String:String]()) { (parsedResult, error) in
            
            if let error = error {
                
                self.setSearchStatus(latitude, longitude: longitude, currentPage: page, totalPages: nil, executed: false)
                
                completionHandler(results: nil, error: error.localizedDescription)
                println("Error \(error.debugDescription)")
            }
            else {
                
                if let photosDictionary = parsedResult["photos"] as? [String:AnyObject] {
                    
                    let totalPages = photosDictionary["pages"] as! Int
                    
                    self.setSearchStatus(latitude, longitude: longitude, currentPage: page, totalPages: totalPages, executed: true)
                    
                    if totalPages > 0 {
                        
                        completionHandler(results: photosDictionary["photo"] as? [[String: AnyObject]], error: nil)
                    }
                    else {
                        
                        completionHandler(results: nil, error: nil)
                    }
                    
                }
                else if let result = parsedResult as? [String: AnyObject] {
                 
                    let error = self.getJSONErrorMessage(result)
                    completionHandler(results: nil, error: error?.localizedDescription)
                    println("Error \(error.debugDescription)")
                }
            }
        }
    }
    
    private func setSearchStatus(latitude: Double, longitude: Double, currentPage: Int, totalPages: Int?, executed: Bool) {
        
        Status.lastLatitude = latitude
        Status.lastLongitude = longitude
        Status.lastPage = currentPage
        Status.executed = executed
        
        if let pages = totalPages {
            
            Status.numberOfPages = pages
            Status.hasMorePages =  currentPage < totalPages
        }
        else if currentPage == Constants.defaultPage {
            
            Status.numberOfPages = 0
            Status.hasMorePages =  false
        }
        
        println(Status)
    }
    
    // MARK: - Error with JSON
    
    func getJSONErrorMessage(JSONParsed: [String: AnyObject]) -> NSError? {
        
        // Check for error message in JSON response
        var clientError: NSError?

        if let errorMessage = JSONParsed[JSONResponseKeys.ErrorMessage] as? String {
            
            if let code = JSONParsed[JSONResponseKeys.ErrorCode] as? Int {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                clientError =  NSError(domain: "Flickr Error", code: code, userInfo: userInfo)
            }
        }
        
        return clientError
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
