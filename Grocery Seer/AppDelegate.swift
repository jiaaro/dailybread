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

var currentGroceryList = GroceryList()
var grocerySuggestionsList = GroceryList()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    lazy var suggestionGenerationQueue: NSOperationQueue = NSOperationQueue()


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        if let w = window {
            w.tintColor = StyleKit.mainColor()!
        }
        
        if app_has_estore_permission() {
            let user_defaults = NSUserDefaults.standardUserDefaults()
            if let cal_id = user_defaults.stringForKey("calendar_id") {
                self.showMainViewController()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("groceryAdded", object: currentGroceryList, queue: suggestionGenerationQueue) {
            notification in
            update_grocery_suggestions()
        }
        NSNotificationCenter.defaultCenter().addObserverForName("groceryListChanged", object: grocerySuggestionsList, queue: suggestionGenerationQueue) {
            notification in
            update_grocery_suggestions()
        }
        
        return true
    }
    func showMainViewController() {
        currentGroceryList.loadFromCalendar(loadCompletedItems: false)
        grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
        get_estore {
            estore in
            let nc = NSNotificationCenter.defaultCenter()
            
            let updateQueue: NSOperationQueue = NSOperationQueue()
            
            nc.addObserverForName("EKEventStoreChangedNotification", object: estore, queue: updateQueue) {
                notification in
                
                currentGroceryList.updateFromCalendar(false, keepCurrent: true)
                grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
            }
            
        }
        
        if let window = self.window {
            if let storyboard = window.rootViewController?.storyboard {
                if let rootViewController = storyboard.instantiateViewControllerWithIdentifier("appMain") as? UIViewController {
                    window.rootViewController = rootViewController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    
    func application(application: UIApplication!, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]!, reply: (([NSObject : AnyObject]!) -> Void)!) {
        
        switch userInfo?["action"] as String {
        case "getList":
            // requires: (no args)
            currentGroceryList.loadFromCalendar(loadCompletedItems: false) {
                get_calendar {
                    calendar in
                    
                    reply([
                        "status": "success",
                        "listName": calendar.title,
                        "groceries": map(currentGroceryList.list, {
                            [
                                "id": $0.reminder.calendarItemIdentifier,
                                "name": $0.name,
                                "bought": $0.bought ? "yes" : "no",
                            ]
                        })
                    ])
                }
            }
        case "setCompletion":
            // requires: id, completed
            let reminder_id = userInfo?["id"] as String
            let is_complete = userInfo?["completed"] as Bool
            get_reminder_with_identifier(reminder_id) {
                (reminder: EKReminder) in
                reminder.completed = is_complete
                save_reminder(reminder) {
                    reply(["status": "success"])
                }
            }
            
        default:
            reply([
                "status": "error",
                "err": "unrecognized_request"
            ])
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

