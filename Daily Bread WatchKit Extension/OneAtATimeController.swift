//
//  OneAtATimeController.swift
//  Daily Bread
//
//  Created by James Robert on 3/4/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//
import WatchKit
import Foundation


var tracker: [Int: WKInterfaceController] = [:]
class OneAtATimeController: WKInterfaceController {
    
    @IBOutlet weak var grocery_label: WKInterfaceLabel!
    @IBOutlet weak var got_grocery_button: WKInterfaceButton!
    
    var groceries = [empty_list_message]
    var my_i = 0
    var grocery: Grocery {
        return self.groceries[self.my_i]
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
            return "wow"
        case 20:
            return "don’t lose hope!"
        case 30:
            return "looong list"
        case 40:
            return "seriously."
        case 50:
            return "impressive."
        case 60:
            return "grocery hero"
        default:
            return "and this:"
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        let cx = context as! Dictionary<String, AnyObject>
        self.groceries = cx["groceries"] as! [Grocery]
        self.my_i = cx["i"] as! Int
        
        tracker[self.my_i] = self
        
        self.update_UI()
    }
    
    func update_UI() {
        if self.grocery.bought {
            self.grocery_label.setText("you got:")
            
            let checkbox_attrs: [NSObject: AnyObject] = [
                NSForegroundColorAttributeName: UIColor.greenColor(),
            ]
            let name_attrs: [NSObject: AnyObject] = [
                NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                NSForegroundColorAttributeName: UIColor.grayColor(),
            ]
            
            let btn_str = NSMutableAttributedString(string: "✓", attributes: checkbox_attrs)
            btn_str.appendAttributedString(NSAttributedString(string: " \(self.grocery.name)", attributes: name_attrs))
            
            self.got_grocery_button.setAttributedTitle(btn_str)
        }
        else {
            let name_attrs: [NSObject: AnyObject] = [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
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

class OneAtATimeDoneController: WKInterfaceController {
    var my_i = 0
    var groceries = [empty_list_message]
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        let cx = context as! Dictionary<String, AnyObject>
        self.groceries = cx["groceries"] as! [Grocery]
        self.my_i = cx["i"] as! Int
        
        tracker[self.my_i] = self
    }
    @IBAction func doneButton() {
        self.dismissController()
    }
}