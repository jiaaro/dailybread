//
//  GlanceController.swift
//  Daily Bread
//
//  Created by James Robert on 4/30/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import Foundation
import WatchKit


class GlanceController: WKInterfaceController {
    
    @IBOutlet weak var listTitleLabel: WKInterfaceLabel!
    @IBOutlet weak var recentlyAddedTitleLabel: WKInterfaceLabel!
    @IBOutlet weak var lastShoppedLabel: WKInterfaceLabel!
    @IBOutlet weak var listLengthLabel: WKInterfaceLabel!
    @IBOutlet weak var table: WKInterfaceTable!
    
    var listTitle = "Loading…"
    var recentAdditions: [String] = []
    var suggestion = "loading…"
    var listLength = 0
    var lastShopped = "never"
    var ui_is_stale = true
    
    override init() {
        super.init()
        self.refresh_data()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.renderUI()
    }
    override func willActivate() {
        super.willActivate()
        self.refresh_data()
    }
    func refresh_data() {
        WKInterfaceController.openParentApplication(["action": "getGlanceData"]) {
            [weak self] (replyInfo, error) in
            
            self?.listTitle = replyInfo["listName"]! as! String
            self?.recentAdditions = replyInfo["recentAdditions"] as! [String]
            self?.suggestion = replyInfo["topSuggestion"]! as! String
            self?.listLength = replyInfo["listLength"]! as! Int
            self?.lastShopped = replyInfo["lastShopped"]! as! String
            
            self?.ui_is_stale = true
            
            self?.renderUI()
            return
        }
    }
    func renderUI() {
        if !ui_is_stale {
            return
        }

        self.listTitleLabel.setText(self.listTitle)
        self.listLengthLabel.setText("\(self.listLength)")
        self.lastShoppedLabel.setText(self.lastShopped)
        
        // Base case
        if self.recentAdditions.count == 0 {
            self.recentlyAddedTitleLabel.setHidden(true)
            self.table.setNumberOfRows(1, withRowType: "topSuggestion")
            
            let row = self.table.rowControllerAtIndex(0) as! SuggestionRow
            row.label.setText(self.suggestion)
            
            return
        }
        
        self.recentlyAddedTitleLabel.setHidden(false)
        self.table.setNumberOfRows(self.recentAdditions.count, withRowType: "recentlyAdded")
        
        for i in 0..<self.recentAdditions.count {
            let row = self.table.rowControllerAtIndex(i) as! RecentlyAddedRow
            row.label.setText(self.recentAdditions[i])
        }
        
    }
}

class RecentlyAddedRow: NSObject {
    @IBOutlet weak var label: WKInterfaceLabel!
}

class SuggestionRow: NSObject {
    @IBOutlet weak var label: WKInterfaceLabel!
}