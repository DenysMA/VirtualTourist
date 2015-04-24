//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 16/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    private var locations = [Location]()
    private var tmpLocation: Location?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Set map region
        restoreMapRegion()
        
        // Get locations
        locations = fetchAllLocations()
        
        // Add map annotations
        loadLocations()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBarHidden = true
        
    }
    
    // Shared context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    
    func fetchAllLocations() -> [Location] {
        
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        
        // Return the results, cast to an array of Person objects,
        // or an empty array of Person objects
        return results as? [Location] ?? [Location]()
    }

    
    func loadLocations() {
        
        var annotations = [MKPointAnnotation]()
        var annotation: MKPointAnnotation!
        
        // Create annotations
        for location in locations {
            
            annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = location.name
            annotations.append(annotation)
            
        }
        
        // Add annotations to the mapView
        mapView.addAnnotations(annotations)
        
    }
    
    // MARK: - Restore Map Region
    
    func restoreMapRegion() {
        
        // Get last map region
        if let mapRegion = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion") as? Dictionary<String, AnyObject> {
            
            let longitude = mapRegion["longitude"] as! CLLocationDegrees
            let latitude = mapRegion["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = mapRegion["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = mapRegion["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: true)
        }
        else {
            
            // Default map region
            let region = MKCoordinateRegionMake(CLLocationCoordinate2D(latitude: 0, longitude: 0), MKCoordinateSpanMake(150, 360))
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Map View Delegate
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        // Create dictionary with region values
        let mapRegion = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Save last region config in NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject(mapRegion, forKey: "mapRegion")
        
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        // Configure Annotation
        
        if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationView") as? MKPinAnnotationView {
            pinView.annotation = annotation
            return pinView
        }
        else {
            
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            
            // Create album or detail button
            let rightButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            rightButton.frame = CGRectMake(0, 0, 25, 25)
            rightButton.setImage(UIImage(named: "album"), forState: UIControlState.Normal)
            rightButton.tag = 1
            
            // Create delete button
            let leftButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            leftButton.frame = CGRectMake(0, 0, 20, 20)
            leftButton.setImage(UIImage(named: "trash"), forState: UIControlState.Normal)
            leftButton.tag = 2
            
            // Configure annotation view
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.draggable = true
            pinView.rightCalloutAccessoryView = rightButton;
            pinView.leftCalloutAccessoryView = leftButton;
            return pinView
        }
    
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        // When callout right Accessory is taped , open up albumViewController
        if let location = getLocationFromAnnotation(view) {
            
            // Album button pressed
            if control.tag == 1 {
                
                // When there are no photos for this location show a message
                if location.content == Location.LocationContext.Empty {
                    
                    let message = UIAlertView(title: "Photos", message: "There are not images for this location. Drag pin to another location or delete it.", delegate: nil, cancelButtonTitle: "OK")
                    message.show()
                    return
                }
                
                // Otherwise show album ViewController
                performSegueWithIdentifier("showAlbums", sender: location)
                return
            }
            
            // Trash button pressed
            removePinLocation(view, location: location)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        switch newState {
            
        // Dragging starting
        case MKAnnotationViewDragState.Starting: tmpLocation = getLocationFromAnnotation(view)
            
        // Dragging ending
        case MKAnnotationViewDragState.Ending:
            if let location = tmpLocation {
                
                // Update coordinates in model
                location.latitude = view.annotation.coordinate.latitude
                location.longitude = view.annotation.coordinate.longitude
                
                // Set content location to pending, so it will pre-fetch images for new coordinates
                location.content = Location.LocationContext.Pending
                tmpLocation = nil
                // Save context
                CoreDataStackManager.sharedInstance().saveContext()
            }
        // Other states
        default: println("Pin being dragged")
            
        }
        
    }
    
    @IBAction func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        
        // If gesture began, add a new annotation
        if gesture.state == UIGestureRecognizerState.Began {
            
            // Get touch position in mapView and conver it to map coordinates
            let touchPosition = gesture.locationInView(mapView)
            let mapCoordinate = mapView.convertPoint(touchPosition, toCoordinateFromView: mapView)
            
            // Add anotation to mapView and core data
            addAnotation(mapCoordinate)
            
        }
    }
    
    func addAnotation(coordinates: CLLocationCoordinate2D ) {
        
        // Create annotation
        let annotation = MKPointAnnotation()
        
        // Create dictionary with location parameters
        let locationProperties: [String : AnyObject] = [
            "latitude": coordinates.latitude,
            "longitude": coordinates.longitude,
            "name": "Dropped Pin"
        ]
        
        // Set annotation properties
        annotation.coordinate = coordinates
        annotation.title = "Dropped Pin"
        
        // Add annotation to the mapView
        mapView.addAnnotation(annotation)

        // Add a new location object to the context
        let locationToBeAdded = Location(dictionary: locationProperties, context: sharedContext)
        locations.append(locationToBeAdded)
        
        // Save context
        CoreDataStackManager.sharedInstance().saveContext()
    
    }
    
    func removePinLocation(annotationView: MKAnnotationView, location: Location) {
        
        // Remove pin from mapview
        self.mapView.removeAnnotation(annotationView.annotation)
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) {
            // Delete object from context and mapView
            self.sharedContext.deleteObject(location)
            dispatch_async(dispatch_get_main_queue()) {
                // Save context
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    
    func getLocationFromAnnotation(annotationView: MKAnnotationView) -> Location? {
        
        // Get the location object for a specific annotation view, filtering by coordinates
        let mapLocations = locations.filter() { (location: Location) -> Bool in
            let coordinates = annotationView.annotation.coordinate
            return location.latitude == coordinates.latitude && location.longitude == coordinates.longitude
        }
        
        // Return location
        if mapLocations.count > 0 {
            return mapLocations[0]
        }
        
        return nil
    }
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get AlbumViewController and pass the selected location
        if let identifier = segue.identifier {
            
            if identifier == "showAlbums" {
                
                let albumVC = segue.destinationViewController as! AlbumViewController
                albumVC.location = sender as! Location
            }
            
        }
        
    }
    

}
