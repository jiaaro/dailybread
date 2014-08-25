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

extension GroceryList {
    func hasAnyCompletedItems() -> Bool {
        for item in self.list {
            if item.bought {
                return true
            }
        }
        return false
    }
}







func name_set(groceries: Array<Grocery>) -> NSSet {
    return NSSet(array: groceries.map {
        $0.name.lowercaseString
    })
}

class GrocerySuggestion {
    var name: String
    var occurences = [NSDate]()
    
    init(name: String, occurences: [NSDate]) {
        self.name = name
        self.occurences = occurences
    }
}

var suggestions: Array<GrocerySuggestion>!
func get_grocery_sugguestion_set(completed: (Array<GrocerySuggestion>)->()) {
    if let s = suggestions {
        completed(s)
        return
    }

    let current_grocery_names = name_set(currentGroceryList.list)
    let groceries = grocerySuggestionsList.list
    var grocery_occurences = [String:[NSDate]]()
    
    for grocery in groceries {
        let key = grocery.name.lowercaseString
        let reminder = grocery.reminder
        
        if grocery_occurences[key] == nil {
            grocery_occurences[key] = []
        }

        grocery_occurences[key]!.append(
            reminder.creationDate ?? reminder.completionDate ?? reminder.lastModifiedDate!
        )
    }

    var suggestion_candidates = (name_set(groceries).allObjects as Array<String>)
    
    suggestion_candidates.sort({
        grocery_occurences[$0.lowercaseString]!.count > grocery_occurences[$1.lowercaseString]!.count
    })
    suggestions = suggestion_candidates.map({
        let occurences = grocery_occurences[$0.lowercaseString]!
        return GrocerySuggestion(name: $0, occurences: occurences)
    })
    
    completed(suggestions)
}

func get_grocery_sugguestions(input:String, completed: (Array<GrocerySuggestion>)->()) {
    get_grocery_sugguestion_set {
        suggestions in
        
        let current_list_names = name_set(currentGroceryList.list)
        
        completed(suggestions.filter {
            grocery in
            
            // don't show anything in the current list
            if current_list_names.containsObject(grocery.name.lowercaseString) {
                return false
            }
            // if the filter string is empty, show everything else
            if countElements(input) == 0 {
                return true
            }
            return grocery.name.lowercaseString.hasPrefix(input.lowercaseString)
        })
    }
}
