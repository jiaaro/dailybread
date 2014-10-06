import EventKit
import UIKit

func send_user_to_settings() {
    let alert = UIAlertController(title: "Reminders Access", message: "This app needs to access to your Reminders to work. This lets you add groceries with Siri, sync with iCloud, and share your grocery list.\n\nReminders are in the privacy section of this app’s settings.", preferredStyle: .Alert)
    
    let default_action = UIAlertAction(title: "Open Settings", style: .Default) { action in
        UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString))
        return
    }
    
    alert.addAction(default_action)
    dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().keyWindow.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        return
    }
}

var _estore: EKEventStore!
func get_estore(completed: (EKEventStore) -> ()) {
    if _estore != nil {
        completed(_estore)
        return
    }
    
    _estore = EKEventStore()
    
    switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder) {
    case .NotDetermined:
        _estore.requestAccessToEntityType(EKEntityTypeReminder) {
            (granted: Bool, err: NSError?) in
            if granted && (err == nil) {
                completed(_estore)
            }
            else {
                _estore = nil
                send_user_to_settings()
            }
        }
    case .Authorized:
        completed(_estore)
    default:
        _estore = nil
        send_user_to_settings()
    }
}

func get_calendars(completed: (([EKCalendar])->())) {
    get_estore {
        estore in
        
        println("getting calendars")
        
        var cals = estore.calendarsForEntityType(EKEntityTypeReminder) as [EKCalendar]
        completed(cals)
    }
}
func get_default_calendar(completed: (EKCalendar) -> () ) {
    get_calendars {
        calendars in
        
        let cals = calendars.filter() {
            switch $0.title.lowercaseString {
            case "grocery", "groceries", "grocery list", "groceries list":
                return true
            default:
                return false
            }
        }
        if cals.count > 0 {
            completed(cals[0])
        }
        else {
            get_estore {
                estore in
                
                let cal = EKCalendar(forEntityType:EKEntityTypeReminder, eventStore: estore)
                cal.title = "Grocery List"
                estore.saveCalendar(cal, commit: true, error: nil)
                
                completed(cal)
            }
        }
    }
}

var calendar: EKCalendar!
func get_calendar(completed: (EKCalendar)->()) {
    if calendar != nil {
        completed(calendar)
        return
    }
    
    let user_defaults = NSUserDefaults.standardUserDefaults()
    
    get_estore {
        estore in
        
        if let calendar_id = user_defaults.stringForKey("calendar_id") {
            if let cal = estore.calendarWithIdentifier(calendar_id) {
                calendar = cal
                completed(cal)
                return
            }
        }
        
        get_default_calendar {
            cal in
            set_calendar(cal)
            completed(cal)
        }
    }
}
func set_calendar(cal: EKCalendar) {
    let user_defaults = NSUserDefaults.standardUserDefaults()
    user_defaults.setObject(cal.calendarIdentifier, forKey: "calendar_id")
    
    calendar = cal
}

func get_estore_and_calendar(completed: (EKEventStore, EKCalendar) -> ()) {
    get_estore { estore in
        get_calendar { calendar in
            completed(estore, calendar)
        }
    }
}

extension GroceryList {
    func loadFromCalendar(loadCompletedItems:Bool = false) {
        get_estore_and_calendar {
            (estore, calendar) in
            
            var remindersPredicate: NSPredicate
            
            if loadCompletedItems {
                 remindersPredicate = estore.predicateForCompletedRemindersWithCompletionDateStarting(nil, ending: nil, calendars: [calendar])
            }
            else {
                remindersPredicate = estore.predicateForIncompleteRemindersWithDueDateStarting(nil, ending: nil, calendars: [calendar])
            }
            
            estore.fetchRemindersMatchingPredicate(remindersPredicate) {
                reminders in
                
                self.list = (reminders as Array<EKReminder>).map {
                    Grocery(reminder: $0)
                }
                
                self.sendChangedNotification()
            }
        }
    }
    func updateFromCalendar(loadCompletedItems: Bool, keepCurrent: Bool) {
        get_estore {
            estore in
            
            get_calendar() {
                calendar in
                
                let current_reminder_ids = NSSet(array: self.list.map { $0.reminder.calendarItemIdentifier })
                let predicate = estore.predicateForRemindersInCalendars([calendar])
                
                estore.fetchRemindersMatchingPredicate(predicate) {
                    reminders in
                    
                    self.list = (reminders as Array<EKReminder>).filter { reminder in
                        if keepCurrent && current_reminder_ids.containsObject(reminder.calendarItemIdentifier) {
                            return true
                        }

                        if loadCompletedItems {
                            return reminder.completed
                        }
                        else {
                            return !reminder.completed
                        }
                    }.map {
                        Grocery(reminder: $0)
                    }
                    
                    self.sendChangedNotification()
                }
            }
        }
    }
}


func create_reminder(name: String, completed: (EKReminder) -> ()) {
    get_estore {
        estore in
        get_calendar {
            calendar in
            
            var reminder = EKReminder(eventStore: estore)
            reminder.title = name
            reminder.completed = false
            reminder.calendar = calendar
            completed(reminder)
            
            save_reminder(reminder) {}
        }
    }
}

func save_reminder(reminder: EKReminder, completed: () -> ()) {
    get_estore {
        estore in
        var err: NSError?
        estore.saveReminder(reminder, commit: true, error: &err)
        
        if let err = err {
            println(err)
        }
        else {
            completed()
        }
    }
}

func delete_reminder(reminder: EKReminder) {
    get_estore {
        estore in
        var err: NSError?
        estore.removeReminder(reminder, commit: true, error: &err)
    }
}
