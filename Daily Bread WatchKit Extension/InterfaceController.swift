//
//  InterfaceController.swift
//  Daily Bread WatchKit Extension
//
//  Created by James Robert on 1/13/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import WatchKit
import WatchConnectivity
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
            cd.openParentApplication([
                    "action": "setCompletion",
                    "id": self.id,
                    "completed": _bought,
                ])
        }
    }
    
    init(_ grocery_data: [String:String]) {
        self.id = grocery_data["id"]!
        self.name = grocery_data["name"]!
        self._bought = (grocery_data["bought"] == "yes")
    }
}

class ConnectivityDelegate: NSObject, WCSessionDelegate {
    var session: WCSession
    var activation_complete_cb: (() -> ())?
    
    override init() {
        session = WCSession.default
        super.init()
        session.delegate = self
        session.activate()
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let cb = activation_complete_cb {
            cb()
        }
    }
    
    public func openParentApplication(
            _ action: [String:Any],
            reply: ((_ replyInfo: [String:Any], _ error: Any?) -> ())? = nil
    ) {
        if session.isReachable {
            session.sendMessage(
                action,
                replyHandler: { replyData in
                    DispatchQueue.main.async {
                        reply?(replyData, nil)
                    }
                }, errorHandler: { error in
                    DispatchQueue.main.async {
                        reply?([:], error)
                    }
                })
        }
    }
}
var cd = ConnectivityDelegate()

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
        cd.activation_complete_cb = {
            [weak self] () in
            self?.refresh_data()
        }
        self.refresh_data()
    }
    
    @IBAction func showOneAtATime() {
        let to_buy = groceries.filter { !$0.bought }
        var names = Array<String>(repeating: "OneAtATimeInterface", count: to_buy.count)
        let cxs = (0...to_buy.count).map {
            ["i": $0, "groceries": to_buy]
        }
        names.append("OneAtATimeDoneInterface")

        self.presentController(withNames: names, contexts: cxs)
    }
    
    @IBAction func showChangeList() {
        cd.openParentApplication(["action": "getLists"]) {
            [weak self]
            (replyInfo, error) in
            
            self?.presentController(withName: "ChangeListInterface", context: replyInfo)
            return
        }
    }

    @IBAction func menuItemRefresh() {
        self.refresh_data()
    }
    func refresh_data() {
        cd.openParentApplication(["action": "getList"]) {
            [weak self] (replyInfo, error) in
            
            let grocery_info_list = replyInfo["groceries"]! as! [[String:String]]

            self?.list_name = replyInfo["listName"]! as! String
            self?.groceries = grocery_info_list.map {
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
        
        let grocery_count = self.groceries.count
        
        groceryTable.setNumberOfRows(grocery_count, withRowType: "groceryRow")
        
        for i in 0..<grocery_count {
            let row = groceryTable.rowController(at: i) as! groceryRowController
            let grocery = self.groceries[i]
            
            row.reset_fields_hack()
            row.set_values(text: grocery.name, checked: grocery.bought)
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let grocery = self.groceries[rowIndex]
        grocery.bought = !grocery.bought
        
        let row = table.rowController(at: rowIndex) as! groceryRowController
        row.set_values(text: grocery.name, checked: grocery.bought)
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
