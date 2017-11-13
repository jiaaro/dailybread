//
//  AddGroceryViewController.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation
import UIKit


class AddGroceryViewController: UIViewController {
    
    var grocery_suggestions: Array<GrocerySuggestion> = []
    
    @IBOutlet var tableview: UITableView!
    @IBOutlet var groceryInput: UITextField!
    @IBOutlet weak var navBar: UINavigationBar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateSuggestions("")
        
        tableview.dataSource = self
        tableview.delegate = self
        
        groceryInput.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        groceryInput.becomeFirstResponder()
    }
    
    func updateSuggestions(_ text: String) {
        get_grocery_sugguestions(text) { [weak self]
            grocery_suggestions in
            if let strong_self = self {
                strong_self.grocery_suggestions = grocery_suggestions
                strong_self.tableview.reloadData()
            }
        }
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAddingGrocery(_ sender: AnyObject) {
        self.close()
    }
    
    func createGroceryAndClose(_ grocery_name: String) {
        if !grocery_name.isEmpty {
            currentGroceryList.add(grocery_name)
        }
        self.close()
    }
    
    @IBAction func saveGroceryWithSender(_ sender: AnyObject) {
        self.createGroceryAndClose(groceryInput.text!)
    }
    
    @IBAction func textChangedWithSender(_ sender: AnyObject) {
        self.updateSuggestions(groceryInput.text!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension AddGroceryViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
            
        let text = NSMutableString(string: textField.text!)
        text.replaceCharacters(in: range, with: string)
            
        self.updateSuggestions(text as String)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.updateSuggestions("")
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.createGroceryAndClose(groceryInput.text!)
        return false
    }
}

extension AddGroceryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let suggestion = grocery_suggestions[indexPath.item]
        groceryInput.text = suggestion.name
        currentGroceryList.add(groceryInput.text!)
        self.close()
        return nil
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont(name: "AvenirNext-Medium", size: 14.0)
        cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 9.0)
        
        cell.textLabel?.textColor = UIColor.gray
        cell.detailTextLabel?.textColor = UIColor.gray
        
        cell.backgroundColor = UIColor.clear
    }
}

extension AddGroceryViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return grocery_suggestions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //var cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "suggestionCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestionCell", for: indexPath)
        
        let suggestion = self.grocery_suggestions[indexPath.item]
        
        cell.textLabel?.text = suggestion.name
        cell.detailTextLabel?.text = "×\(suggestion.occurences.count)"
        cell.detailTextLabel?.accessibilityLabel = "\(suggestion.occurences.count) times"
        cell.accessibilityHint = "adds \(suggestion) to your grocery list"
        
        return cell
    }

}
