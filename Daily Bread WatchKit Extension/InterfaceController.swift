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
    let name: String
    var bought: Bool
    
    init(_ grocery_data: [String:String]) {
        self.id = grocery_data["id"]!
        self.name = grocery_data["name"]!
        self.bought = (grocery_data["bought"] == "yes")
    }
}

let empty_list_message = Grocery(["id": "0", "name": "No Data", "bought": "no"])

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var groceryTable: WKInterfaceTable!
    
    var needs_ui_refresh = true
//    
//    let cb_unchecked: UIImage = StyleKit.imageOfCheckbox(isChecked: false)
//    let cb_checked: UIImage = StyleKit.imageOfCheckbox(isChecked: true)
    
    var groceries: [Grocery] = [
        empty_list_message,
    ]
    
    override init() {
        super.init()
        println("init")
        
        self.refresh_data()
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.refresh_ui()
    }
    @IBAction func menuItemRefresh() {
        self.refresh_data()
    }
    func refresh_data() {
        WKInterfaceController.openParentApplication([:]) {
            [weak self] (replyInfo, error) in
            
            println("got reply:")
            println(replyInfo)
            
            let grocery_info_list = replyInfo["groceries"]! as [[String:String]]
            
            self?.groceries = map(grocery_info_list) {
                Grocery($0)
            }
            
            if self?.groceries.count == 0 {
                self?.groceries = [empty_list_message]
            }
            
            self?.needs_ui_refresh = true
            self?.refresh_ui()
            return
        }
    }
    func refresh_ui() {
        println("refresh_data")
        if !self.needs_ui_refresh {
            return
        }
        self.needs_ui_refresh = false
        
        let grocery_count = countElements(self.groceries)
        let row_difference = grocery_count - groceryTable.numberOfRows
        
        if row_difference > 0 {
            let indexes = NSIndexSet(indexesInRange: NSRange(0..<row_difference))
            groceryTable.insertRowsAtIndexes(indexes, withRowType: "groceryRow")
        }
        if row_difference < 0 {
            let indexes = NSIndexSet(indexesInRange: NSRange(0..<(-row_difference)))
            groceryTable.removeRowsAtIndexes(indexes)
        }
        //groceryTable.setNumberOfRows(grocery_count, withRowType: "groceryRow")
        
        for i in 0..<grocery_count {
            let row = groceryTable.rowControllerAtIndex(i) as groceryRowController
            let grocery = self.groceries[i]
            
            println("setting text: \(grocery.name)")
            row.label.setText(grocery.name)
            
            if grocery.bought {
                row.img.setImageNamed("checked_box")
            }
            else {
                row.img.setImageNamed("unchecked_box")
            }
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let grocery = self.groceries[rowIndex]
        grocery.bought = !grocery.bought
        
        let row = table.rowControllerAtIndex(rowIndex) as groceryRowController
        if grocery.bought {
            row.img.setImageNamed("checked_box")
        }
        else {
            row.img.setImageNamed("unchecked_box")
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.refresh_ui()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

