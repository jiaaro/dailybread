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
    var created: Date? {
        return self.reminder.creationDate
    }
    var completed_date: Date? {
        return self.reminder.completionDate
    }
    
    init(name: String, bought: Bool, reminder: EKReminder) {
        self.name = name
        self.bought = bought
        self.reminder = reminder
    }
    convenience init?(reminder: EKReminder) {
        if reminder.title == nil {
            return nil
        }
        self.init(name: reminder.title, bought: reminder.isCompleted, reminder: reminder)
    }
    
    func toggle_bought() {
        bought = !bought
        reminder.isCompleted = bought
        save_reminder(reminder) {}
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
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "groceryListChanged"), object: self)
    }
    
    func add(_ name: String) {
        create_reminder(name) {
            reminder in
            
            guard let grocery = Grocery(reminder: reminder) else {
                return
            }
            
            self.list.append(grocery)
            self.sendChangedNotification()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "groceryAdded"), object: self, userInfo: ["grocery": grocery])
        }
    }
    func delete(_ grocery: Grocery) {
        delete_reminder(grocery.reminder)
        self.list = self.list.filter() { $0 !== grocery }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "groceryDeleted"), object: self, userInfo: ["grocery": grocery])
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

extension GroceryList {
    func get_top(_ n: Int?, by_sort: (Grocery, Grocery) -> Bool) -> [Grocery] {
        let n_: Int
        if n == nil || n! > self.list.endIndex {
            n_ = self.list.endIndex
        }
        else {
            n_ = n!
        }
        
        let sorted_groceries = self.list.sorted {
            switch ($0.created, $1.created) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
        
        return Array(sorted_groceries[0..<n_])
    }
    func mostRecentlyAdded(_ n: Int? = nil) -> [Grocery] {
        return self.get_top(n) {
            switch ($0.created, $1.created) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
    }
    func mostRecentlyCompleted(_ n: Int? = nil) -> [Grocery] {
        return self.get_top(n) {
            switch ($0.completed_date, $1.completed_date) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
    }
}






func name_set(_ groceries: Array<Grocery>) -> NSSet {
    return NSSet(array: groceries.map {
        $0.name.lowercased()
    })
}

class GrocerySuggestion {
    var name: String
    var occurences = [Date]()
    
    init(_ name: String, occurences: [Date]) {
        self.name = name
        self.occurences = occurences
    }
}

let stock_suggestions = [
    "Bread",
    "Milk",
    "Eggs",
    "Coffee",
    "Chocolate",
    "Water",
    "Peanut butter",
    "Yogurt",
    "Orange Juice",
    "Soda",
    "Laundry Detergent",
    "Tea",
    "Breakfast bars",
    "Cheese",
    "Oatmeal",
    "Mac ‘n Cheese",
    "Wine",
    "Guacamole",
    "Chocolate Chip Cookies",
    "Soylent",
    "Beer",
    "Pita Bread",
    "Greek Yogurt",
    "Apple Juice",
    "Carrots",
    "Celery",
    "Potatoes",
    "String Beans",
    "Crackers",
    "Chicken",
    "Burgers",
    "Veggie Burgers",
    "Steak",
    "Ground Beef",
    "Ground Chicken",
    "Ground Turkey",
    "Cold Cuts",
    "Ginger Snaps",
    "Turkey",
    "Ham",
    "Tomatoes",
    "Brussels Sprouts",
    "Bananas",
    "Strawberries",
    "Blueberries",
    "String Beans",
    "Mushrooms",
    "Pork",
    "Canned Beans",
    "Apples",
    "Strawberry Jam",
    "Grape Jam",
    "Peaches",
    "Oranges",
    "Clementines",
    "Salmon",
    "Tilapia",
    "Lamb",
    "Bagels",
    "Croutons",
    "Break Crumbs",
    "Shrimp",
    "Cheddar Cheese",
    "Swiss Cheese",
    "Mozzarella",
    "Parmesan Cheese",
    "Pasta",
    "Corn",
    "Peas",
    "Rice",
    "Spaghetti",
    "Linguini",
    "Onions",
    "Red Onions",
    "White Onions",
    "Green Onions",
    "Bacon",
    "Turkey Bacon",
    "Salt",
    "Pepper",
    "Garlic",
    "Mashed Potatoes",
    "Sweet Potatoes",
    "Ketchup",
    "Mustard",
    "Steak Sauce",
    "Butter",
    "Broccoli",
    "Paper towels",
    "Napkins",
    "Chips",
    "Salsa",
    "Olive Oil",
    "Tomato Sauce",
    "Barbecue Sauce",
    "Brown rice",
    "Tuna",
    "Halibut",
    "Trout",
    "Mackerel",
    "Peas",
    "Peas and Carrots",
    "Greek Yogurt",
    "Tofu",
    "Extra Firm Tofu",
    "String Cheese",
    "Almonds",
    "Peanuts",
    "Hummus",
]
func mk_grocery_sugguestion_set(completed: (Array<GrocerySuggestion>)->()) {
    let groceries = grocerySuggestionsList.list
    var grocery_occurences = [String:[Date]]()
    
    for grocery in groceries {
        let key = grocery.name.lowercased()
        let reminder = grocery.reminder
        
        if grocery_occurences[key] == nil {
            grocery_occurences[key] = []
        }

        grocery_occurences[key]!.append(
            reminder.creationDate ?? reminder.completionDate ?? reminder.lastModifiedDate!
        )
    }

    let suggestion_candidates_set = name_set(groceries)
    var suggestion_candidates = (suggestion_candidates_set.allObjects as! Array<String>)
    
    suggestion_candidates = suggestion_candidates.sorted {
        a, b in

        let occurrances1 = grocery_occurences[a.lowercased()]!
        let occurrances2 = grocery_occurences[b.lowercased()]!

        return grocery_rank_score(occurrances1) > grocery_rank_score(occurrances2)
    }
    var new_suggestions: [GrocerySuggestion] = suggestion_candidates.map({
        let occurences = grocery_occurences[$0.lowercased()]!
        return GrocerySuggestion($0, occurences: occurences)
    })

    
    for stock_suggestion in stock_suggestions {
        if suggestion_candidates_set.contains(stock_suggestion.lowercased()) {
            continue
        }
        new_suggestions.append(GrocerySuggestion(stock_suggestion, occurences: []))
    }
    
    completed(new_suggestions)
}

var suggestions: Array<GrocerySuggestion>!
func get_grocery_sugguestion_set(completed: (Array<GrocerySuggestion>)->()) {
    if let s = suggestions {
        completed(s)
        return
    }
    
    mk_grocery_sugguestion_set {
        new_suggestions in
        suggestions = new_suggestions
        completed(suggestions)
    }
}

func get_grocery_sugguestions(_ input:String, completed: (Array<GrocerySuggestion>)->()) {
    get_grocery_sugguestion_set {
        suggestions in
        
        let current_list_names = name_set(currentGroceryList.list)
        
        completed(suggestions.filter {
            grocery in
            
            // don't show anything in the current list
            if current_list_names.contains(grocery.name.lowercased()) {
                return false
            }
            // if the filter string is empty, show everything else
            if input.count == 0 {
                return true
            }
            
            let simplified_name = grocery.name.lowercased()
            let simplified_input = input.lowercased()
            
            var chars = " \t\n\"'"
            if !input.isEmpty {
                chars = "/+_[]- \t\n:"
            }
            
            let words: [String] = simplified_name.components(separatedBy: CharacterSet(charactersIn: chars))
            for word in words {
                if word.hasPrefix(simplified_input) {
                    return true
                }
            }
            return simplified_name.hasPrefix(simplified_input)
        })
    }
}

var updating = false
func update_grocery_suggestions() {
    DispatchQueue.global(qos: .utility).async {
        if updating { return }
        updating = true

        mk_grocery_sugguestion_set {
            new_suggestions in
            suggestions = new_suggestions
            updating = false
        }
    }
}
