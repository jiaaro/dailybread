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
    @IBOutlet weak var heading: UILabel!
    
    override func setSharedStyles() {
        super.setSharedStyles()
        self.heading.textColor = StyleKit.mainColor()
    }
}




class OnboardingStep2: OnboardingViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var heading: UILabel!
    
    var selected_index = 0
    var cals: [EKCalendar] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        get_estore_permission {
            estore_permission in
            
            if estore_permission {
                get_calendars { [weak self]
                    calendars in
                    if let strongself = self {
                        strongself.cals = calendars
                        DispatchQueue.main.async {
                            strongself.tableView.reloadData()
                        }
                    }
                }
            }
            else {
                send_user_to_settings(self)
            }
        }
    }
    
    override func setSharedStyles() {
        super.setSharedStyles()
        self.heading.textColor = StyleKit.mainColor()
    }
    
    @IBAction func continueToMain(_ sender: UIButton) {
        get_estore_permission {
            estore_permission in
            if !estore_permission {
                send_user_to_settings(self)
                return
            }
        
            let app_delegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        
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
    
}

extension OnboardingStep2: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.selected_index = indexPath.item
        self.tableView.reloadData()
        return nil
    }
}

extension OnboardingStep2: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cals.count + 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        
        var label: String
        if (indexPath.item == 0) {
            label = "Create one called “Grocery”"
        }
        else {
            label = self.cals[indexPath.item - 1].title
        }
        
        if (indexPath.item == self.selected_index) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        
        cell.textLabel?.text = label
        
        return cell
    }
}
