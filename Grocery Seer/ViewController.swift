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
    @IBOutlet weak var navBar: UINavigationBar!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.dataSource = self
        tableview.delegate = self
        
        clearButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 14.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.groceryListWasChanged(_:)), name: NSNotification.Name(rawValue: "groceryListChanged"), object: currentGroceryList)
    }
    
    func setup_ui() {
        get_calendar { [weak self]
            calendar in
            let title = calendar.title
            self?.navbarTitle?.title = title
        }
        self.tableview.reloadData()
        
        if currentGroceryList.hasAnyCompletedItems() {
            self.clearButton.isHidden = false
            self.tableview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.clearButton.frame.height, right: 0)
        }
        else {
            self.clearButton.isHidden = true
            self.tableview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        
        self.emptyListOverlay.isHidden = currentGroceryList.count > 0
    }
    
    @objc func addGrocery() {
        self.performSegue(withIdentifier: "addGrocerySegue", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setup_ui()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func groceryListWasChanged(_ notification: NSNotification!) {
        DispatchQueue.main.async {
            self.setup_ui()
        }
    }

    @IBAction func clearCompletedWithSender(_ sender: AnyObject) {
        currentGroceryList.loadFromCalendar(loadCompletedItems: false)
        self.clearButton.isHidden = true
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // special case for empty, "add grocery" cell
        if indexPath.item >= currentGroceryList.count {
            return nil
        }
        
        let grocery = currentGroceryList[indexPath.item]
        grocery.toggle_bought()
        self.setup_ui()
        return nil
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentGroceryList.count + 1
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // special case for empty, "add grocery" cell
        if indexPath.item >= currentGroceryList.count {
            return false
        }
        return true
    }
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath) {
            
            let grocery = currentGroceryList[indexPath.item]
            currentGroceryList.delete(grocery)
            
            tableView.deleteRows(at:[indexPath], with: .automatic)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if indexPath.item < currentGroceryList.count {
            let selected_bg_view = UIView()
            selected_bg_view.backgroundColor = StyleKit.orangeWhite()
            cell.selectedBackgroundView = selected_bg_view
        }
        else {
            let button = UIButton(frame: cell.frame)
            button.backgroundColor = UIColor.clear
            button.addTarget(self, action: #selector(ViewController.addGrocery), for: .touchUpInside)
            cell.addSubview(button)
            cell.selectionStyle = .none
        }
        
        // special case for empty, "add grocery" cell
        if indexPath.item >= currentGroceryList.count {
            return cell
        }
        
        let grocery = currentGroceryList[indexPath.item]
        
        cell.textLabel?.text = grocery.name
        cell.imageView?.image = StyleKit.imageOfCheckbox(withIsChecked: grocery.bought)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueid = segue.identifier
        if (segueid == "showPopover") {
            let destinationVC = segue.destination
            destinationVC.modalPresentationStyle = .popover
            destinationVC.popoverPresentationController?.delegate = self
        }
        else if segueid == "addGrocerySegue" {
            let destinationVC = segue.destination
            destinationVC.modalPresentationStyle = .custom
            destinationVC.transitioningDelegate = addGroceryTransitionDelegate
        }
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
