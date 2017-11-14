//
//  AppDelegate.swift
//  Grocery Seer
//
//  Created by James Robert on 6/19/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation
import UIKit
import EventKit
import WatchConnectivity

var currentGroceryList = GroceryList()
var grocerySuggestionsList = GroceryList()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    var window: UIWindow?
    lazy var suggestionGenerationQueue: OperationQueue = OperationQueue()
    var session: WCSession?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        if let w = window {
            w.tintColor = StyleKit.mainColor()!
        }
        
        if app_has_estore_permission() {
            let user_defaults = UserDefaults.standard
            if let cal_id = user_defaults.string(forKey: "calendar_id"), !cal_id.isEmpty {
                self.showMainViewController()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "groceryAdded"), object: currentGroceryList, queue: suggestionGenerationQueue) {
            notification in
            update_grocery_suggestions()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "groceryListChanged"), object: grocerySuggestionsList, queue: suggestionGenerationQueue) {
            notification in
            update_grocery_suggestions()
        }
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        
        return true
    }
    func showMainViewController() {
        if let window = self.window {
            if let storyboard = window.rootViewController?.storyboard {
                let rootViewController = storyboard.instantiateViewController(withIdentifier: "appMain")
                window.rootViewController = rootViewController
                window.makeKeyAndVisible()
            }
        }
        DispatchQueue.global(qos: .userInteractive).async {
            currentGroceryList.loadFromCalendar(loadCompletedItems: false) {
                grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
            }
            get_estore {
                estore in
                let nc = NotificationCenter.default
                
                let updateQueue: OperationQueue = OperationQueue()
                
                nc.addObserver(forName: NSNotification.Name(rawValue: "EKEventStoreChangedNotification"), object: estore, queue: updateQueue) {
                    notification in
                    
                    currentGroceryList.updateFromCalendar(loadCompletedItems: false, keepCurrent: true) {
                        grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
                    }
                }
            }
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iphone watch session activated")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    func sessionDidDeactivate(_ session: WCSession) {
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler reply: @escaping ([String : Any]) -> Void) {
        let application = UIApplication.shared;

        let actionName = message["action"] as! String
        
        let bg_task_id = application.beginBackgroundTask(withName: "watchkit action: \(actionName)") {
            reply([
                "status": "error",
                "err": "backgroundTaskExpired"
            ])
            return
        }
        
        switch actionName {
        case "getList":
            // requires: (no args)
            currentGroceryList.loadFromCalendar(loadCompletedItems: false) {
                get_calendar {
                    calendar in
                    
                    reply([
                        "status": "success",
                        "listName": calendar.title,
                        "groceries": currentGroceryList.list.map {
                            [
                                "id": $0.reminder.calendarItemIdentifier,
                                "name": $0.name,
                                "bought": $0.bought ? "yes" : "no",
                            ]
                        }
                    ])
                    application.endBackgroundTask(bg_task_id)
                }
            }
        case "setCompletion":
            // requires: id, completed
            let reminder_id = message["id"] as! String
            let is_complete = message["completed"] as! Bool
            get_reminder_with_identifier(reminder_id) {
                (reminder: EKReminder) in
                reminder.isCompleted = is_complete
                save_reminder(reminder) {
                    reply(["status": "success"])
                    application.endBackgroundTask(bg_task_id)
                }
            }
        case "getLists":
            // requires: (no args)
            get_calendars {
                calendars in
                get_calendar {
                    current_cal in
                    
                    let lists = calendars.map {
                        calendar in
                        return [
                            "title": calendar.title,
                            "id": calendar.calendarIdentifier
                        ]
                    }
                    reply([
                        "status": "success",
                        "calendars": lists,
                        "current_calendar": current_cal.calendarIdentifier
                    ])
                    application.endBackgroundTask(bg_task_id)
                }
            }
        case "setList":
            // requires: id
            let calender_id = message["id"] as! String
            
            get_estore {
                estore in
                if let cal = estore.calendar(withIdentifier: calender_id) {
                    set_calendar(cal)
                    currentGroceryList.loadFromCalendar(loadCompletedItems: false) {
                        reply(["status": "success"])
                        application.endBackgroundTask(bg_task_id)
                    }
                    grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
                }
            }
        case "getGlanceData":
            // requires: (no args)
            
            currentGroceryList.loadFromCalendar(loadCompletedItems: false) {
                grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true) {
                    get_calendar {
                        calendar in
                        
                        let recentAdditions = currentGroceryList.mostRecentlyAdded(3).map {
                            $0.name
                        }
                        var lastShopped = "never"
                        if let d = grocerySuggestionsList.mostRecentlyCompleted(1).first?.completed_date {
                            let days = Int(round(-d.timeIntervalSinceNow / (60*60*24)))
                            
                            switch (d.toString(), days) {
                            case (Date().toString(), _):
                                lastShopped = "today"
                            case (Date(timeIntervalSinceNow: -24*60*60).toString(), _):
                                lastShopped = "yesterday"
                            case (_, 0...99):
                                lastShopped = "\(days) days"
                            default:
                                lastShopped = "ages ago"
                            }
                        }
                        get_grocery_sugguestions("") {
                            suggestions in
                            reply([
                                "status": "success",
                                "listName": calendar.title,
                                "recentAdditions": recentAdditions,
                                "topSuggestion": suggestions.first?.name ?? "Treat Yourself!",
                                "listLength": currentGroceryList.count,
                                "lastShopped": lastShopped,
                            ])
                            application.endBackgroundTask(bg_task_id)
                        }
                    }
                }
            }
            
        default:
            reply([
                "status": "error",
                "err": "unrecognized_request"
            ])
            application.endBackgroundTask(bg_task_id)
        }
    }
}

