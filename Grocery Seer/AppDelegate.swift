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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        if let w = window {
            w.tintColor = StyleKit.mainColor()!
        }
        
        currentGroceryList.loadFromCalendar(loadCompletedItems: false)
        grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
        
        NSNotificationCenter.defaultCenter().addObserverForName("groceryAdded", object: currentGroceryList, queue: nil) {
                notification in
                suggestions = nil
                get_grocery_sugguestion_set("", {s in })
        }
        
        get_estore {
            estore in
            let nc = NSNotificationCenter.defaultCenter()
            nc.addObserverForName("EKEventStoreChangedNotification", object: estore, queue: nil) {
                notification in
                currentGroceryList.updateFromCalendar(false, keepCurrent: true)
                // grocerySuggestionsList.loadFromCalendar(loadCompletedItems: true)
            }

        }
        
        return true
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

