//
//  InterfaceController.swift
//  Daily Bread WatchKit Extension
//
//  Created by James Robert on 1/13/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import WatchKit
import Foundation

class Grocery {
    let id: String
    var name: String
    var _bought: Bool
    var bought: Bool {
        get {
           return _bought
        }
        set {
            if self.id == "0" {
                return
            }
            _bought = newValue
            WKInterfaceController.openParentApplication([
                    "action": "setCompletion",
                    "id": self.id,
                    "completed": _bought,
                ], reply: nil)
        }
    }
    
    init(_ grocery_data: [String:String]) {
        self.id = grocery_data["id"]!
        self.name = grocery_data["name"]!
        self._bought = (grocery_data["bought"] == "yes")
    }
}

let empty_list_message = Grocery(["id": "0", "name": "Loading…", "bought": "no"])

var data_is_stale = false
class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var groceryTable: WKInterfaceTable!
    
    var needs_ui_refresh = true
    var list_name = "Loading…"
    var groceries: [Grocery] = [
        empty_list_message,
    ]
    
    override init() {
        super.init()
        self.refresh_data()
    }
    
    @IBAction func showOneAtATime() {
        let to_buy = groceries.filter { !$0.bought }
        var names = Array<String>(count: to_buy.count, repeatedValue: "OneAtATimeInterface")
        var cxs = (0...to_buy.count).map {
            ["i": $0, "groceries": to_buy]
        }
        names.append("OneAtATimeDoneInterface")

        self.presentControllerWithNames(names, contexts: cxs)
    }
    
    @IBAction func showChangeList() {
        WKInterfaceController.openParentApplication(["action": "getLists"]) {
            [weak self]
            (replyInfo, error) in
            
            let cx: [String: AnyObject?] = [
                "calendars": replyInfo["calendars"],
                "current_calendar": replyInfo["current_calendar"]
            ]
            
            self?.presentControllerWithName("ChangeListInterface", context: replyInfo)
            return
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    @IBAction func menuItemRefresh() {
        self.refresh_data()
    }
    func refresh_data() {
        WKInterfaceController.openParentApplication(["action": "getList"]) {
            [weak self] (replyInfo, error) in
            
            let grocery_info_list = replyInfo["groceries"]! as! [[String:String]]

            self?.list_name = replyInfo["listName"]! as! String
            self?.groceries = map(grocery_info_list) {
                Grocery($0)
            }
            
            if self?.groceries.count == 0 {
                empty_list_message.name = "Empty List"
                self?.groceries = [empty_list_message]
            }
            
            self?.needs_ui_refresh = true
            self?.refresh_ui()
            return
        }
    }
    func refresh_ui(force: Bool = false) {
        if data_is_stale {
            data_is_stale = false
            self.refresh_data()
            return
        }
        if !self.needs_ui_refresh && !force {
            return
        }
        self.needs_ui_refresh = false
        
        self.setTitle(self.list_name)
        
        let grocery_count = count(self.groceries)
        let row_difference = grocery_count - groceryTable.numberOfRows
        
        groceryTable.setNumberOfRows(grocery_count, withRowType: "groceryRow")
        
        for i in 0..<grocery_count {
            let row = groceryTable.rowControllerAtIndex(i) as! groceryRowController
            let grocery = self.groceries[i]
            
            row.reset_fields_hack()
            row.set_values(grocery.name, checked: grocery.bought)
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let grocery = self.groceries[rowIndex]
        grocery.bought = !grocery.bought
        
        let row = table.rowControllerAtIndex(rowIndex) as! groceryRowController
        row.set_values(grocery.name, checked: grocery.bought)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.refresh_ui(force: true)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
