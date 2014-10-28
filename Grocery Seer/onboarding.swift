//
//  onboarding.swift
//  Daily Bread
//
//  Created by James Robert on 10/9/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation
import UIKit
import EventKit

@IBDesignable class OnboardingViewController: UIViewController {
    override func viewDidLoad() {
        self.setSharedStyles()
    }
    func setSharedStyles() {
        self.view.backgroundColor = StyleKit.orangeWhite()
    }
}


class OnboardingStep1: OnboardingViewController {
    
}




class OnboardingStep2: OnboardingViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    
    var selected_index = 0
    var cals: [EKCalendar] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        
        get_estore_permission {
            estore_permission in
            
            if estore_permission {
                get_calendars { [weak self]
                    calendars in
                    if let strongself = self {
                        strongself.cals = calendars
                        dispatch_async(dispatch_get_main_queue()) {
                            strongself.tableView.reloadData()
                        }
                    }
                }
            }
            else {
                send_user_to_settings(current_view_controller: self)
            }
        }
    }
    
    @IBAction func continueToMain(sender: AnyObject) {
        let user_defaults = NSUserDefaults.standardUserDefaults()
        let app_delegate: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
        
        if self.selected_index == 0 {
            create_calendar("Grocery") {
                calendar in
                set_calendar(calendar)
                app_delegate?.showMainViewController();
            }
        }
        else {
            set_calendar(self.cals[self.selected_index - 1])
            app_delegate?.showMainViewController();
        }
    }
    
}

extension OnboardingStep2: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.textLabel.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        self.selected_index = indexPath.item
        self.tableView.reloadData()
        return nil
    }
}

extension OnboardingStep2: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cals.count + 1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath) as UITableViewCell
        
        var label: String
        if (indexPath.item == 0) {
            label = "Create one called “Grocery”"
        }
        else {
            label = self.cals[indexPath.item - 1].title
        }
        
        if (indexPath.item == self.selected_index) {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        
        
        cell.textLabel.text = label
        
        return cell
    }
}