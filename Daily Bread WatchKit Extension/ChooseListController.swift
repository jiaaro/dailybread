//
//  OneAtATimeController.swift
//  Daily Bread
//
//  Created by James Robert on 3/4/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//
import WatchKit
import Foundation


class ChooseListController: WKInterfaceController {
    
    @IBOutlet weak var listTable: WKInterfaceTable!
    
    var lists: [[String:String]] = []
    var current_list = ""
    var parent: InterfaceController?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        let cx = context as! [String:AnyObject]
        
        self.lists = cx["calendars"]! as! [[String:String]]
        self.current_list = cx["current_calendar"]! as! String
        
        self.update_UI()
    }
    
    func update_UI() {
        self.listTable.setNumberOfRows(self.lists.count, withRowType: "listRow")
        
        for i in 0..<self.lists.count {
            let row = self.listTable.rowControllerAtIndex(i) as! ListRowController
            let list = self.lists[i]
            let is_selected = list["id"] == self.current_list
            
            row.setListName(list["title"]!, selected: is_selected)
        }
    }
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        let list = self.lists[rowIndex]
        let action = [
            "action": "setList",
            "id": list["id"]!,
        ]
        WKInterfaceController.openParentApplication(action) {
            [weak self] (replyInfo, error) in

            data_is_stale = true

            self?.dismissController()
            return
        }
    }
}

class ListRowController: NSObject {
    @IBOutlet weak var label: WKInterfaceLabel!
    
    func setListName(var name: String, selected: Bool) {
        let bold_font = UIFont.boldSystemFontOfSize(UIFont.systemFontSize())
        
        var attrs: [NSObject: AnyObject] = [:]
        if selected {
            name = "‣ \(name)"
            attrs[NSFontAttributeName] = bold_font
        }
        self.label.setText("")
        self.label.setAttributedText(NSMutableAttributedString(string: name, attributes: attrs))
    }
}