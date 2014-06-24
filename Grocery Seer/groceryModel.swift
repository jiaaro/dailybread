//
//  groceryModel.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation
import EventKit


class Grocery {
    var name: String
    var bought: Bool = false
    var reminder: EKReminder
    
    init(name: String, bought: Bool, reminder: EKReminder) {
        self.name = name
        self.bought = bought
        self.reminder = reminder
    }
    convenience init(reminder: EKReminder) {
        self.init(name: reminder.title, bought: reminder.completed, reminder: reminder)
    }
    
    func toggle_bought() {
        bought = !bought
        reminder.completed = bought
        save_reminder(reminder, {})
    }
}

class GroceryList {
    var list: Array<Grocery>
    var count: Int {
        return self.list.count
    }
    
    init(groceries: Array<Grocery>) {
        self.list = groceries
    }
    convenience init() {
        self.init(groceries: [])
    }
    
    subscript(index: Int) -> Grocery {
        get {
            return self.list[index]
        }
    }
    
    func currentGroceries() -> Array<Grocery> {
        return self.list.filter() { !$0.bought }
    }
    
    func sendChangedNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName("groceryListChanged", object: self)
    }
    
    func add(name: String) {
        create_reminder(name) {
            reminder in
            
            let grocery = Grocery(reminder: reminder)
            
            self.list.append(grocery)
            self.sendChangedNotification()
            NSNotificationCenter.defaultCenter().postNotificationName("groceryAdded", object: self, userInfo: ["grocery": grocery])
        }
    }
    func delete(grocery: Grocery) {
        delete_reminder(grocery.reminder)
        self.list = self.list.filter() { $0 !== grocery }
        NSNotificationCenter.defaultCenter().postNotificationName("groceryDeleted", object: self, userInfo: ["grocery": grocery])
    }
}







func name_set(groceries: Array<Grocery>) -> NSSet {
    return NSSet(array: groceries.map {
        $0.name.lowercaseString
    })
}

class GrocerySuggestion {
    var name: String
    var occurences: Int = 0
    
    init(name: String, occurences: Int) {
        self.name = name
        self.occurences = occurences
    }
}

var suggestions: Array<GrocerySuggestion>!
func get_grocery_sugguestion_set(input:String, completed: (Array<GrocerySuggestion>)->()) {
    if let s = suggestions {
        completed(s)
        return
    }
    
    let groceries = grocerySuggestionsList.list
    var grocery_counts = Dictionary<String, Int>()
    
    for grocery in groceries {
        let key = grocery.name.lowercaseString
        
        if let n = grocery_counts[key] {
            grocery_counts[key] = n + 1
        }
        else {
            grocery_counts[key] = 1
        }
    }
    
    var suggestion_candidates = (name_set(groceries).allObjects as Array<String>)
    
    suggestion_candidates.sort({
        grocery_counts[$0.lowercaseString]! > grocery_counts[$1.lowercaseString]!
    })
    suggestions = suggestion_candidates.map({
        let occurences = grocery_counts[$0.lowercaseString]!
        return GrocerySuggestion(name: $0, occurences: occurences)
    })
    
    completed(suggestions)
    

}

func get_grocery_sugguestions(input:String, completed: (Array<GrocerySuggestion>)->()) {
    get_grocery_sugguestion_set(input) {
        suggestions in
        
        let current_list_names = name_set(currentGroceryList.list.filter({ !$0.bought }))
        
        completed(suggestions.filter {
            if current_list_names.containsObject($0.name.lowercaseString) {
                return false
            }
            return $0.name.lowercaseString.hasPrefix(input.lowercaseString)
        })
    }
}
