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
        let context = self.persistentContainer.viewContext
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try! controller.performFetch()
        
        preloadItems()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        let item = controller.object(at: indexPath)
        
        cell.textLabel?.text = item.text
        if item.read {
            cell.textLabel?.textColor = .gray
        } else {
            cell.textLabel?.textColor = .black
        }
        
        return cell
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
        print("updated!")
    }
    
    @IBAction func marnAllUnread() {
        let context = persistentContainer.viewContext
        let update = NSBatchUpdateRequest(entityName: Item.entity().name!)
        update.resultType = .updatedObjectIDsResultType
        update.propertiesToUpdate = ["read": false]
        
        let result = try! context.execute(update) as! NSBatchUpdateResult
        let updatedIDs = result.result as! [NSManagedObjectID]
        
        let changes = [NSUpdatedObjectsKey : updatedIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        print("unread!")
    }
    
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

