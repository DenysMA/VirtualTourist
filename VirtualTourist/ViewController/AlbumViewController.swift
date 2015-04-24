//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Denys Medina Aguilar on 17/04/15.
//  Copyright (c) 2015 Denys Medina Aguilar. All rights reserved.
//

import UIKit
import CoreData

class AlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UITextFieldDelegate {

    
    @IBOutlet weak var tableView: UITableView!
    internal var location: Location!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch results
        fetchedResultsController.performFetch(nil)
        
        // Set delegate
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Show navigation bar
        navigationController?.navigationBarHidden = false
    }
    
    // Shared context variable
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // Create fetchResultContoller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request
        let fetchRequest = NSFetchRequest(entityName: "Album")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Set predicate to show only the albums of a specific location
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location);
        
        // Create fetchresults controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    // MARK: TableView DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Get number of objects in section from fetchedResultsController
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get album object
        let album = fetchedResultsController.objectAtIndexPath(indexPath) as! Album
        
        // Dequeue and configure cell
        let cell = tableView.dequeueReusableCellWithIdentifier("albumCell", forIndexPath: indexPath) as! AlbumTableViewCell
        configureCell(cell, withAlbum: album)
        
        return cell
    }
    
     // MARK: TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get album object
        let album = fetchedResultsController.objectAtIndexPath(indexPath) as! Album
        
        // Perform segue
        performSegueWithIdentifier("showPhotos", sender: album)
    }
    
    func configureCell(cell: AlbumTableViewCell, withAlbum album: Album) {
        
        // Set album name
        cell.albumTextField.text = album.name
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        // Create rowAction to delete a row by swiping
        let rowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Delete") { (rowAction, indexPath) in
    
            // Get album object
            let album = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Album
            // Delete album from the context
            self.sharedContext.deleteObject(album)
            // Save contexts
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        // Set rowAction color
        rowAction.backgroundColor = UIColor.redColor()
        
        return [rowAction]
    }
    
    // MARK: FetchResultsController Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
    }

    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! AlbumTableViewCell
                let album = controller.objectAtIndexPath(indexPath!) as! Album
                self.configureCell(cell, withAlbum: album)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    // MARK : Add Album
    
    @IBAction func addAlbum(sender: UIBarButtonItem) {
        
        // Get number of albums
        let albumCount = tableView.numberOfRowsInSection(0) + 1
        
        // Create dictionary for a new album with a default name
        let albumParameters = [
            "name": "Album \(albumCount)",
            "location": location]
        
        // Create album
        let newAlbum = Album(dictionary: albumParameters, context: sharedContext)
        
        // Save context
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK : Update Album's Name
    
    func updateAlbumName(name: String, album: Album) {
        
        // Replace alnbum's name
        album.name = name
        // Save context
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK : Textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        // Get object edited and update name
        let textFieldLocation = tableView.convertPoint(textField.center, fromView: textField)
        
        if let indexPath = tableView.indexPathForRowAtPoint(textFieldLocation) {
         
            let album = fetchedResultsController.objectAtIndexPath(indexPath) as! Album
            updateAlbumName(textField.text, album: album)
        }
        
        // Dismiss keyboard
        textField.resignFirstResponder()
        
        return true
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Validate segue identifier
        if let identifier = segue.identifier {
            
            if identifier == "showPhotos" {
                
                // Get a reference to PhotoViewController and set the album selected
                let photoVC = segue.destinationViewController as! PhotoViewController
                photoVC.album = sender as! Album
            }
        }
    }
    
}
