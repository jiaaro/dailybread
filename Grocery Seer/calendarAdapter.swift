import EventKit
import UIKit

func send_user_to_settings(var current_view_controller: UIViewController! = nil) {
    if current_view_controller == nil {
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            if vc.isViewLoaded() && vc.view.window != nil {
                current_view_controller = vc
            }
        }
    }
    
    // if nothing was passed in and we couldn't find a VC to use, give up
    if current_view_controller == nil {
        return
    }
    
    let alert = UIAlertController(title: "Reminders Access", message: "This app needs to access to your Reminders to work. This lets you add groceries with Siri, sync with iCloud, and share your grocery list.\n\nReminders are in the privacy section of this app’s settings.", preferredStyle: .Alert)
    
    let default_action = UIAlertAction(title: "Open Settings", style: .Default) { action in
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    alert.addAction(default_action)
    dispatch_async(dispatch_get_main_queue()) {
        current_view_controller.presentViewController(alert, animated: true, completion: nil)
        return
    }
}

func get_estore_permission(completed: (Bool) -> Void) {
    switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder) {
    case .NotDetermined:
        EKEventStore().requestAccessToEntityType(EKEntityTypeReminder) {
            (granted: Bool, err: NSError?) in
            if granted && (err == nil) {
                completed(true)
            }
            else {
                completed(false)
            }
        }
    case .Authorized:
        completed(true)
    default:
        completed(false)
    }
}

var _estore: EKEventStore!
func get_estore(completed: (EKEventStore) -> ()) {
    if _estore != nil {
        completed(_estore)
        return
    }
    
    _estore = EKEventStore()
    
    get_estore_permission {
        permission in
        if permission {
            completed(_estore)
        }
        else {
            _estore = nil
            send_user_to_settings()
        }
    }
}

func app_has_estore_permission() -> Bool {
    let status = EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder)
    return status == EKAuthorizationStatus.Authorized;
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
            create_calendar("Grocery") {
                cal in
                completed(cal)
            }
        }
    }
}
func create_calendar(name: String, completed: (EKCalendar)->Void) {
    get_estore {
        estore in
        
        let cal = EKCalendar(forEntityType:EKEntityTypeReminder, eventStore: estore)
        cal.title = name
        cal.source = estore.defaultCalendarForNewReminders().source
        
        var err: NSError?
        estore.saveCalendar(cal, commit: true, error: &err)
        
        if let err = err {
            println(err)
        }
        
        completed(cal)
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
