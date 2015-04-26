//
//  ViewController.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var navbarTitle: UINavigationItem!
    @IBOutlet weak var emptyListOverlay: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.separatorColor = UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.1)
        
        tableview.dataSource = self
        tableview.delegate = self
        
        clearButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 14.0)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groceryListWasChanged:", name: "groceryListChanged", object: currentGroceryList)
    }
    
    func setup_ui() {
        get_calendar { [weak self]
            calendar in
            var title = calendar.title
            self?.navbarTitle.title = title
        }
        self.tableview.reloadData()
        
        if currentGroceryList.hasAnyCompletedItems() {
            self.clearButton.hidden = false
            self.tableview.contentInset = UIEdgeInsets(top: 44.0, left: 0, bottom: self.clearButton.frame.height, right: 0)
        }
        else {
            self.clearButton.hidden = true
            self.tableview.contentInset = UIEdgeInsets(top: 44.0, left: 0, bottom: 0, right: 0)
        }
        
        
        self.emptyListOverlay.hidden = currentGroceryList.count > 0
    }
    
    func addGrocery() {
        self.performSegueWithIdentifier("addGrocerySegue", sender: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.setup_ui()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func groceryListWasChanged(notification: NSNotification!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setup_ui()
        }
    }

    @IBAction func clearCompleted(sender: AnyObject) {
        currentGroceryList.loadFromCalendar(loadCompletedItems: false)
        self.clearButton.hidden = true
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // special case for empty, "add grocery" cell
        if indexPath.item == currentGroceryList.count {
            return nil
        }
        
        let grocery = currentGroceryList[indexPath.item]
        grocery.toggle_bought()
        self.setup_ui()
        return nil
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentGroceryList.count + 1
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // special case for empty, "add grocery" cell
        if indexPath.item == currentGroceryList.count {
            return false
        }
        return true
    }
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
            let grocery = currentGroceryList[indexPath.item]
            currentGroceryList.delete(grocery)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Automatic)
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.item != currentGroceryList.count {
            let selected_bg_view = UIView()
            selected_bg_view.backgroundColor = StyleKit.orangeWhite()
            cell.selectedBackgroundView = selected_bg_view
        }
        else {
            let button = UIButton(frame: cell.frame)
            button.backgroundColor = UIColor.clearColor()
            button.addTarget(self, action: "addGrocery", forControlEvents: .TouchUpInside)
            cell.addSubview(button)
            cell.selectionStyle = .None
        }
        
        
        
        // special case for empty, "add grocery" cell
        if indexPath.item == currentGroceryList.count {
            return cell
        }
        
        
        let grocery = currentGroceryList[indexPath.item]
        
        cell.textLabel?.text = grocery.name
        cell.imageView?.image = StyleKit.imageOfCheckboxWithIsChecked(grocery.bought)
        if grocery.bought {
            cell.accessibilityHint = "checks off \(grocery.name)"
        }
        else {
            cell.accessibilityHint = "unchecks \(grocery.name)"
        }
        
        return cell
    }
}

// popover related code
var addGroceryTransitionDelegate = ZippyModalTransitioningDelegate()
extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueid = segue.identifier
        if (segueid == "showPopover") {
            let destinationVC = segue.destinationViewController as! UIViewController
            destinationVC.popoverPresentationController?.delegate = self
        }
        else if segueid == "addGrocerySegue" {
            let destinationVC = segue.destinationViewController as! UIViewController
            destinationVC.modalPresentationStyle = .Custom
            destinationVC.transitioningDelegate = addGroceryTransitionDelegate
        }
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}