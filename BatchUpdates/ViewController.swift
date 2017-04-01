//
//  ViewController.swift
//  BatchUpdates
//
//  Created by Samuel Ryan Goodwin on 4/1/17.
//  Copyright © 2017 Roundwall Software. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BatchUpdates")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var controller: NSFetchedResultsController<Item> = {
        // This is so we don't have to keep up with data changes ourselves. Especially when you're displaying a list like this, this is super handy.
        
        let context = self.persistentContainer.viewContext
        let request: NSFetchRequest<Item> = Item.fetchRequest() // Manually making fetch requests is so iOS 7-
        
        // At least one sort descriptor is required
        request.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        // This is how it tells us when to update the UI. I use the super-generic delegate method and just reload the table, you could use the finer-grain methods to do fancy things like animate the changes and only update the rows that changed. I was lazy so I just reload the whole table.
        controller.delegate = self
        
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This makes the fetched results controller actually start doing stuff. Don't forget it.
        try! controller.performFetch()
        
        // This is because I was lazy and didn't want to load the items from the internet or let users add their own items.
        preloadItems()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // The fetched results controller handles putting stuff into sections even if you provide a section key when you make it. Either way this line stays the same.
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        let item = controller.object(at: indexPath)
        
        // Technically if we wanted to do more than this you'd want to move this work off to a view model and use a cell subclass, but I'm lazy and the demo here isn't for making a beautiful app, just to show some functionality.
        
        cell.textLabel?.text = item.text
        if item.read {
            cell.textLabel?.textColor = .gray
        } else {
            cell.textLabel?.textColor = .black
        }
        
        return cell
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // This is where I take the easy way out and just reload the entire table if any single object changes. At least this method is not called for every individual change, only once for each NSManagedObjectContext save that results in changes to the data the fetched results controller cares about.
        
        tableView.reloadData()
        print("updated!")
    }
    
    // The magic is here! Technically you'd wanna move this into some model layer thing and not do the work directly in your view controller. The controller should just be the manager of your "office", not actually doing work. That's what employees are for. More explanation about the process can be found here: https://developer.apple.com/library/content/featuredarticles/CoreData_Batch_Guide/BatchUpdates/BatchUpdates.html#//apple_ref/doc/uid/TP40016086-CH2-SW1
    
    @IBAction func marnAllUnread() {
        let context = persistentContainer.viewContext
        
        let update = NSBatchUpdateRequest(entityName: Item.entity().name!) // Typing string values here raw leaves room for typos to ruin your fun.
        update.resultType = .updatedObjectIDsResultType
        update.propertiesToUpdate = ["read": false] // Typos here will ruin your fun, be careful
        
        let result = try! context.execute(update) as! NSBatchUpdateResult
        
        // Because batch updates are operating directly on your persistent store instead of on the context like regular fetches, we need to tell the context that stuff changed so everyone can know what's up.
        let updatedIDs = result.result as! [NSManagedObjectID]
        let changes = [NSUpdatedObjectsKey : updatedIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        print("unread!")
    }
    
    // This one is the same only it turns everything to read instead of unread
    
    @IBAction func markAllAsRead() {
        let context = persistentContainer.viewContext
        let update = NSBatchUpdateRequest(entityName: Item.entity().name!)
        update.resultType = .updatedObjectIDsResultType
        update.propertiesToUpdate = ["read": true]
        
        let result = try! context.execute(update) as! NSBatchUpdateResult
        let updatedIDs = result.result as! [NSManagedObjectID]
        
        let changes = [NSUpdatedObjectsKey : updatedIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        print("read!")
    }
    
    // Making items to show in the list because loading them from the internet or making UI to let the user create items would take more work, haha. 
    
    private func preloadItems() {
        defer {
            print("All set!")
        }
        
        let context = persistentContainer.viewContext
        guard try! context.count(for: Item.fetchRequest()) == 0 else {
            return
        }
        
        for i in 0..<10 {
            let item = Item(context: context)
            item.text = "Some random crap \(i)"
            item.read = false
        }
        
        try! context.save()
    }
}

