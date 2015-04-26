//
//  groceryRowController.swift
//  Daily Bread
//
//  Created by James Robert on 1/13/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//
import WatchKit
import Foundation

class groceryRowController : NSObject {
    @IBOutlet weak var checked: WKInterfaceGroup!
    @IBOutlet weak var label: WKInterfaceLabel!
    
    func reset_fields_hack() {
        self.label.setText("")
        self.label.setAlpha(0.0)
        self.checked.setBackgroundColor(UIColor.grayColor())
        self.checked.setWidth(0)
        self.checked.setHeight(0)
        self.checked.setCornerRadius(0)
    }
    
    func set_values(text: String, checked: Bool) {
        if checked {
            self.label.setAlpha(0.3)
            
            let single_style: NSNumber = NSUnderlineStyle.StyleSingle.rawValue
            let attrs: [NSObject: AnyObject] = [NSStrikethroughStyleAttributeName: single_style]
            let attributed_string = NSMutableAttributedString(string: text, attributes: attrs)
            
            self.label.setAttributedText(attributed_string)
            
            self.checked.setBackgroundColor(UIColor.grayColor())
            
            self.checked.setHeight(16)
            self.checked.setWidth(4)
            self.checked.setCornerRadius(2)
        }
        else {
            self.label.setAlpha(1.0)
            self.label.setText(text)
            
            self.checked.setBackgroundColor(UIColor.orangeColor())
            
            self.checked.setHeight(24)
            self.checked.setWidth(6)
            self.checked.setCornerRadius(3)
        }
    }
}