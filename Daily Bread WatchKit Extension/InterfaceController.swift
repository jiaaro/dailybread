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
    
    @IBAction func showOneAtATime() {
        let names = Array<String>(count: self.groceries.count, repeatedValue: "OneAtATimeInterface")
        
        let cxs = (0..<groceries.count).map {
            ["i": $0, "groceries": self.groceries]
        }
        self.presentControllerWithNames(names, contexts: cxs)
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
        
        groceryTable.setNumberOfRows(grocery_count, withRowType: "groceryRow")
        
        for i in 0..<grocery_count {
            let row = groceryTable.rowControllerAtIndex(i) as groceryRowController
            let grocery = self.groceries[i]
            
            row.reset_fields_hack()
            row.set_values(grocery.name, checked: grocery.bought)
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let grocery = self.groceries[rowIndex]
        grocery.bought = !grocery.bought
        
        let row = table.rowControllerAtIndex(rowIndex) as groceryRowController
        row.set_values(grocery.name, checked: grocery.bought)
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

var tracker: [Int: OneAtATimeController] = [:]
class OneAtATimeController: WKInterfaceController {
    
    @IBOutlet weak var grocery_label: WKInterfaceLabel!
    @IBOutlet weak var got_grocery_button: WKInterfaceButton!
    
    var groceries = [empty_list_message]
    var my_i = 0
    var grocery: Grocery {
        return self.groceries[my_i]
    }
    var get_this_text: String {
        switch self.my_i {
        case 0:
            return "get this:"
        case 1:
            return "now get this:"
        case 5:
            return "keep going!"
        case 10:
            return "don’t lose hope"
        default:
            return "and this:"
        }
    }
    
    override init() {
        super.init()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        let cx = context as Dictionary<String, AnyObject>
        self.groceries = cx["groceries"] as [Grocery]
        self.my_i = cx["i"] as Int
        
        tracker[self.my_i] = self
        
        self.update_UI()
    }
    
    func update_UI() {
        if self.grocery.bought {
            self.grocery_label.setText("you got:")
            
            let checkbox_attrs: NSDictionary = [
                NSForegroundColorAttributeName: UIColor.greenColor(),
            ]
            let name_attrs: NSDictionary = [
                NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                NSForegroundColorAttributeName: UIColor.grayColor(),
            ]

            let btn_str = NSMutableAttributedString(string: "✓", attributes: checkbox_attrs)
            btn_str.appendAttributedString(NSAttributedString(string: " \(self.grocery.name)", attributes: name_attrs))

            self.got_grocery_button.setAttributedTitle(btn_str)
        }
        else {
            let name_attrs: NSDictionary = [
                NSForegroundColorAttributeName: UIColor.orangeColor(),
            ]
            self.grocery_label.setText(self.get_this_text)
            self.got_grocery_button.setAttributedTitle(NSAttributedString(string: self.grocery.name, attributes: name_attrs))
        }
    }
    @IBAction func tapped() {
        self.grocery.bought = !self.grocery.bought
        self.update_UI()
        tracker[self.my_i+1]?.becomeCurrentPage()
    }
}
