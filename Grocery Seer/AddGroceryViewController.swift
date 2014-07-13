//
//  AddGroceryViewController.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation
import UIKit

class AddGroceryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var grocery_suggestions: Array<GrocerySuggestion> = []
    
    @IBOutlet var tableview: UITableView
    @IBOutlet var groceryInput: UITextField
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateSuggestions("")
        
        tableview.dataSource = self
        tableview.delegate = self
        
        groceryInput.delegate = self
    }
    
    func updateSuggestions(text: String) {
        get_grocery_sugguestions(text) { [weak self]
            grocery_suggestions in
            if let strong_self = self {
                strong_self.grocery_suggestions = grocery_suggestions
                strong_self.tableview.reloadData()
            }
        }
    }
    
    @IBAction func cancelAddingGrocery(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, nil)
    }
    
    @IBAction func saveGrocery(sender: AnyObject) {
        currentGroceryList.add(groceryInput.text)
        self.dismissViewControllerAnimated(true, nil)
    }
    
    @IBAction func textChanged(sender: AnyObject) {
        self.updateSuggestions(groceryInput.text)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return grocery_suggestions.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {

        var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "suggestionCell")
        
        let suggestion = self.grocery_suggestions[indexPath.item]
        
        cell.textLabel.text = suggestion.name
        cell.detailTextLabel.text = "x\(suggestion.occurences)"
        
        return cell
    }
    
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        cell.textLabel.font = UIFont(name: "AvenirNext-Medium", size: 14.0)
        cell.detailTextLabel.font = UIFont(name: "AvenirNext-Regular", size: 9.0)
        
        cell.textLabel.textColor = UIColor.grayColor()
        cell.detailTextLabel.textColor = UIColor.grayColor()
        
        cell.backgroundColor = UIColor.clearColor()
    }
    
    func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath!) -> NSIndexPath! {
        let suggestion = grocery_suggestions[indexPath.item]
        groceryInput.text = suggestion.name
        return nil
    }
    
    func textField(textField: UITextField!,
        shouldChangeCharactersInRange range: NSRange,
        replacementString string: String!) -> Bool {
            
        var text = NSMutableString(string: textField.text)
        text.replaceCharactersInRange(range, withString: string)
            
        self.updateSuggestions(text as String)
        return true
    }
    
    func textFieldShouldClear(textField: UITextField!) -> Bool {
        self.updateSuggestions("")
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}