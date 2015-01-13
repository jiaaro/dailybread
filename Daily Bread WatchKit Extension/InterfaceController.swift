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

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var groceryTable: WKInterfaceTable!
    
    var needs_refresh = true
    
    let cb_unchecked: UIImage = StyleKit.imageOfCheckbox(isChecked: false)
    let cb_checked: UIImage = StyleKit.imageOfCheckbox(isChecked: true)
    var groceries: [Grocery] = [
        Grocery(["id": "0", "name": "No Data", "bought": "no"]),
    ]
    
    override init() {
        super.init()
        println("init")
        WKInterfaceController.openParentApplication([:]) {
            [weak self] (replyInfo, error) in
            
            println("got reply:")
            println(replyInfo)
            
            let grocery_info_list = replyInfo["groceries"]! as [[String:String]]
            
            self?.groceries = map(grocery_info_list) {
                Grocery($0)
            }
            self?.needs_refresh = true
            self?.refresh_data()
            return
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.refresh_data()
    }
    
    func refresh_data() {
        println("refresh_data")
        if !self.needs_refresh {
            return
        }
        self.needs_refresh = false
        
        let grocery_count = countElements(self.groceries)
        
        groceryTable.setNumberOfRows(grocery_count, withRowType: "groceryRow")
        
        for i in 0..<grocery_count {
            let row = groceryTable.rowControllerAtIndex(i) as groceryRowController
            let grocery = self.groceries[i]
            
            row.label.setText(grocery.name)
            
            if grocery.bought {
                row.img.setImage(cb_checked)
            }
            else {
                row.img.setImage(cb_unchecked)
            }
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let grocery = self.groceries[rowIndex]
        grocery.bought = !grocery.bought
        
        let row = table.rowControllerAtIndex(rowIndex) as groceryRowController
        if grocery.bought {
            row.img.setImage(cb_checked)
        }
        else {
            row.img.setImage(cb_unchecked)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.refresh_data()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

