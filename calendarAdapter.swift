import EventKit
import UIKit

var _estore: EKEventStore!
func get_estore(completed: (EKEventStore) -> ()) {
    if _estore {
        completed(_estore)
        return
    }
    
    _estore = EKEventStore()
    
    switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder) {
    case .NotDetermined:
        _estore.requestAccessToEntityType(EKEntityTypeReminder) {
            (granted: Bool, err: NSError!) in
            if granted && !err {
                completed(_estore)
            }
        }
    case .Authorized:
        completed(_estore)
        
    case .Denied, .Restricted:
        break
    }
}

var calendar: EKCalendar!
func get_calendar(completed:((EKCalendar)->())) {
    if calendar {
        completed(calendar)
        return
    }
    
    get_estore {
        estore in
        
        var cals = estore.calendarsForEntityType(EKEntityTypeReminder) as EKCalendar[]
        cals = cals.filter() {
            switch $0.title.lowercaseString {
            case "grocery", "groceries", "grocery list", "groceries list":
                return true
            default:
                return false
            }
        }
        if cals.count > 0 {
            calendar = cals[0]
        }
        else {
            calendar = EKCalendar(forEntityType:EKEntityTypeReminder, eventStore: estore)
            calendar.title = "Grocery List"
            estore.saveCalendar(calendar, commit: true, error: nil)
        }
        
        completed(calendar)
    }
}


extension GroceryList {
    func loadFromCalendar(loadCompletedItems:Bool = false) {
        get_estore {
            estore in
            
            get_calendar() {
                calendar in
                
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
        
        if err {
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
