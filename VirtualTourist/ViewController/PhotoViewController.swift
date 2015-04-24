//
//  PhotoTableViewController.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 18/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    // Storyboard variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var saveCollectionButton: UIButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Album selected
    internal var album: Album!
    
    // Array to store all the collection view changes
    typealias ClosureType = () -> ()
    private var collectionUpdates: [ClosureType]!
    
    // Array of selected indexPaths
    private var selectedItems = [NSIndexPath]()
    
    // Variable to store dowload operations
    private let pendingOperations = PendingOperations()
    
    // Task used to get the list of images from Flickr
    private var searchTask: NSURLSessionDataTask?
    
    // MARK: - View Controller Life-Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate
        fetchedResultsController.delegate = self
        
        // Perform fetch results
        fetchedResultsController.performFetch(nil)
        
        // Set Annotation in map
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: album.location.latitude, longitude: album.location.longitude)
        annotation.title = album.location.name
        mapView.addAnnotation(annotation)
        
        // Set map region
        let region = MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(2, 2))
        mapView.setRegion(region, animated: true)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Hide save button
        saveCollectionButton.hidden = true
        
        // Show navigation bar
        navigationController?.navigationBarHidden = false
        
        if let section = fetchedResultsController.sections![0] as? NSFetchedResultsSectionInfo {
            if section.numberOfObjects == 0 {
                
                // Start getting images from Flickr
                downloadImageSet(Flickr.Constants.defaultPage)
            }
            else {
                
                // Enable selection and new collection button
                collectionView.allowsSelection = true
                collectionView.allowsMultipleSelection = true
                newCollectionButton.enabled = true
                cancelButton.enabled = false
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Cancel operations
        cancel(cancelButton)
        
        // Set to nil delegate
        fetchedResultsController.delegate = nil
        
        // Save context if there are changes
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Set dynamic item size
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: self.view.frame.width * 0.33, height: self.view.frame.width * 0.33)
        flowLayout.invalidateLayout()
        collectionView.updateConstraints()
    }
    
    // Shared context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "album == %@", self.album);
        
        // Create fetchresults controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    // MARK: - Collection DataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Get number of items in section from fetchedResultsController
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get photo object
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // Get photo cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Configure Cell
        configureCell(cell, indexPath: indexPath, photo: photo)
        
        return cell
        
    }
    
    func configureCell(photoCell: PhotoCollectionViewCell, indexPath: NSIndexPath, photo: Photo) {
        
        // Create placeholder
        var placeholderImage = UIImage(named: "placeholder")
        
        // Set placeholder and activity view animating
        photoCell.activityIndicator.startAnimating()
        photoCell.photoImageView.image = placeholderImage
        
        // Check whether indexPath is selected or not to configure the cell
        if let selected = find(selectedItems, indexPath) {
            
            photoCell.photoImageView.alpha = 0.3
            photoCell.deleteImageView.hidden = false
        }
        else {
            
            photoCell.photoImageView.alpha = 1
            photoCell.deleteImageView.hidden = true
        }
        
        // Check state of the photo Image
        switch (photo.state) {
        
        // When Failed state stop animating cell
        case Photo.PhotoState.Failed.rawValue:
            photoCell.activityIndicator.stopAnimating()
            println("failed")
        
        // When New state check collection current state before starting a download
        case Photo.PhotoState.New.rawValue:
            
            //if (!collectionView.dragging && !collectionView.decelerating) {
                startDownloadForRecord(indexPath, photo: photo)
                println("Downloading")
            //}
        
        // When Downloaded state check photoImage property, if its nil start a download
        case Photo.PhotoState.Downloaded.rawValue:
            
            if let image = photo.photoImage {
                
                // Set image and stop animating cell
                photoCell.photoImageView.image = image
                photoCell.activityIndicator.stopAnimating()
                println("Already downloaded")
            }
            else {
                
                // Start dowload if user is not scrolling
                //if (!collectionView.dragging && !collectionView.decelerating) {
                    startDownloadForRecord(indexPath, photo: photo)
                //}
            }
            
        default: return
            
        }
    }
    
    func startDownloadForRecord(indexPath: NSIndexPath, photo: Photo) {
        
        // Check if operation for that index is not in process
        if let downloadOperation = pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        // Create Operation Image Downloader
        let downloader = ImageDownloader(photoRecord: photo)
        
        // Set completion
        downloader.completionBlock = {
            // Check operation status
            if downloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                // Remove operation from downloads array
                self.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                
                // Reload cell if user is not scrolling
                if (!self.collectionView.dragging && !self.collectionView.decelerating) {
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                }
            })
        }
        // Add operation to array of downloads
        pendingOperations.downloadsInProgress[indexPath] = downloader
        // Add operation to queue
        pendingOperations.downloadQueue.addOperation(downloader)
        self.cancelButton.enabled = true
    }
    
    // MARK: - Collection Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Get cell selected
        let photoCell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Get cell to selected state
        photoCell.deleteImageView.hidden = false
        photoCell.photoImageView.alpha = 0.3
        
        // Configure save and new collection buttons
        saveCollectionButton.hidden = false
        newCollectionButton.hidden = true
        
        // Add selected indexPath to array
        selectedItems.append(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Get cell deselected
        let photoCell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Get cell to normal state
        photoCell.deleteImageView.hidden = true
        photoCell.photoImageView.alpha = 1
        
        // Remove indexPath from array
        let index = find(selectedItems, indexPath)
        selectedItems.removeAtIndex(index!)
        
        // Re-configure save and new collection buttons
        saveCollectionButton.hidden = selectedItems.count == 0
        newCollectionButton.hidden = !saveCollectionButton.hidden
        
    }
    
    // MARK: - Flickr Download
    
    func downloadImageSet(page: Int) {
        
        // Disable new collection button and collection selection
        cancelButton.enabled = true
        newCollectionButton.enabled = false
        collectionView.allowsSelection = false
        collectionView.allowsMultipleSelection = false
        activityIndicator.startAnimating()
        
        // Create request
        searchTask = Flickr.sharedInstance().getImageFromFlickrByLatLon(album.location.latitude, longitude: album.location.longitude, page: page) { (photosDictionary, error) in
            
            // Check for errors and show a message to the user
            if let errorString = error {
            
                dispatch_async(dispatch_get_main_queue()) {
                    let alertMessage = UIAlertView(title: "Searching error", message: errorString, delegate: nil, cancelButtonTitle: "OK")
                    alertMessage.show()
                }
            }
            
            else {
                
                // Check for dictionary of photos
                if let photoDict = photosDictionary {
                    
                    // Iterate list of photos and create a managed object
                    for photo in photoDict {
                    
                        var photo = photo
                        photo["album"] = self.album
                        
                        let newphoto = Photo(dictionary: photo, context: self.sharedContext)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                       // Save context
                       CoreDataStackManager.sharedInstance().saveContext()
                        self.activityIndicator.stopAnimating()
                    }
                    
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        // Show message of no photos found
                        let alertMessage = UIAlertView(title: "Album", message: "Sorry, no images were found for this location", delegate: nil, cancelButtonTitle: "OK")
                        alertMessage.show()
                    }

                }
            }
        }
    }
    
    // MARK: - Cancel
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        
        // Cancel Flickr download if there is one in execution
        if searchTask?.state == NSURLSessionTaskState.Running {
            searchTask?.cancel()
        }
        
        // Cancel images download
        if pendingOperations.downloadsInProgress.count > 0 {
            
            pendingOperations.downloadQueue.cancelAllOperations()
            pendingOperations.downloadsInProgress.removeAll(keepCapacity: false)
        }
        
        self.cancelButton.enabled = false
    
    }
    
    // MARK: - Load new collection
    
    @IBAction func loadNewCollection(sender: UIButton) {

        // Check if there are more images available in Flickr for that location
        if Flickr.Status.hasMorePages || !Flickr.Status.executed {
            
            // Delete current photos fro the album
            for photo in fetchedResultsController.sections![0].objects as! [Photo] {
                sharedContext.deleteObject(photo)
            }
            
            // Save context
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Start download
            downloadImageSet(Flickr.Status.lastPage + ( Flickr.Status.executed ? 1 : 0) )
        }
        else {
            
            // Show message when there are more photos in Flickr
            let message = UIAlertView(title: "New Collection", message: "No more photos", delegate: nil, cancelButtonTitle: "OK")
            message.show()
        }
    }
    
    // MARK: - Save Changes
    
    @IBAction func saveCollection(sender: UIButton) {
        
        // Check for items selected
        if selectedItems.count > 0 {
            
            // Delete items from the context
            for selectedIndexPhoto in selectedItems {
                
                let photoToBeDeleted = fetchedResultsController.objectAtIndexPath(selectedIndexPhoto) as! Photo
                sharedContext.deleteObject(photoToBeDeleted)
            }
            
            // Save context
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Reset array of items selectes and configure save and new collection buttons
            selectedItems.removeAll(keepCapacity: false)
            saveCollectionButton.hidden = true
            newCollectionButton.hidden = false
        }
        
    }
    
    // MARK: - FetchResults Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // Create array of updates
        collectionUpdates = [ClosureType]()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
        
            // Add the specific update to the array of closures
            
            switch type {
            case .Insert:
                collectionUpdates.append({
                    self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
                })
            case .Delete:
                collectionUpdates.append( {
                    self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                })
            case .Update:
                collectionUpdates.append( {
                    self.collectionView.reloadItemsAtIndexPaths([indexPath!])
                })
            case .Move:
                collectionUpdates.append( {
                    self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                })
            default:
                return
            }

    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
     
        println("Setting updates")
        
        // Copy collection updates to new variable
        var updates = self.collectionUpdates
        
        collectionView.performBatchUpdates( {
        
            println("Applying updates")
            
            // Execute closures
            for updateBlock in updates {
                updateBlock()
            }
            
            
            }) { finished in
        
                // Check for photos pending of downloading
                let pendingImages = self.fetchedResultsController.sections![0].objects as! [Photo]
                let results = pendingImages.filter() { (photo: Photo) in
                    return photo.photoImage == nil
                }
                
                // If all images have been downloaded, enable buttons and selection
                if (results.count == 0  && !pendingImages.isEmpty) {
                    
                    self.newCollectionButton.enabled = true
                    self.collectionView.allowsSelection = true
                    self.collectionView.allowsMultipleSelection = true
                    self.cancelButton.enabled = false
                }
        }
    }
}
