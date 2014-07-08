//
//  ViewController.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate {
                            
    @IBOutlet var tableview: UITableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.contentInset = UIEdgeInsets(top: 44.0, left: 0, bottom: 0, right: 0)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groceryListWasChanged:", name: "groceryListChanged", object: currentGroceryList)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableview.reloadData()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func groceryListWasChanged(notification: NSNotification!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableview.reloadData()
        }
    }

    
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        cell.textLabel.font = UIFont(name: "AvenirNext-Regular", size: 14.0)
    }
    
    func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath!) -> NSIndexPath! {
        let grocery = currentGroceryList[indexPath.item]
        grocery.toggle_bought()
        self.tableview.reloadData()
        return nil
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return currentGroceryList.count
    }
    func tableView(tableView: UITableView!,
        canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
            return true
    }
    func tableView(tableView: UITableView!,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath!) {
            
            let grocery = currentGroceryList[indexPath.item]
            currentGroceryList.delete(grocery)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Automatic)
    }
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        var cell = UITableViewCell()
        let grocery = currentGroceryList[indexPath.item]
        
        cell.textLabel.text = grocery.name
        cell.imageView.image = StyleKit.imageOfCheckbox(grocery.bought)
        
        return cell
    }
}
