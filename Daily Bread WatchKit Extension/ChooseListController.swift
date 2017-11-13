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
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let cx = context as! [String:AnyObject]
        
        self.lists = cx["calendars"]! as! [[String:String]]
        self.current_list = cx["current_calendar"]! as! String
        
        self.update_UI()
    }
    
    func update_UI() {
        self.listTable.setNumberOfRows(self.lists.count, withRowType: "listRow")
        
        for i in 0..<self.lists.count {
            let row = self.listTable.rowController(at: i) as! ListRowController
            let list = self.lists[i]
            let is_selected = list["id"] == self.current_list
            
            row.setListName(list["title"]!, selected: is_selected)
        }
    }
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let list = self.lists[rowIndex]
        let action = [
            "action": "setList",
            "id": list["id"]!,
        ]
        cd.openParentApplication(action) {
            [weak self] (replyInfo, error) in

            data_is_stale = true

            self?.dismiss()
            return
        }
    }
}

class ListRowController: NSObject {
    @IBOutlet weak var label: WKInterfaceLabel!
    
    func setListName(_ name: String, selected: Bool) {
        var list_name = name;
        let default_font_size = UIFont.preferredFont(forTextStyle: .body).pointSize;
        let bold_font = UIFont.systemFont(ofSize: default_font_size, weight: .bold)
        
        var attrs: [NSAttributedStringKey: Any] = [:]
        if selected {
            list_name = "‣ \(list_name)"
            attrs[NSAttributedStringKey.font] = bold_font
            
        }
        self.label.setText("")
        self.label.setAttributedText(NSMutableAttributedString(string: list_name, attributes: attrs))
    }
}
