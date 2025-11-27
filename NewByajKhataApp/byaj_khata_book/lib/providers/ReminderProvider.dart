import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/ServiceLocator.dart';
import '../data/models/Reminder.dart';

class ReminderProvider with ChangeNotifier {
  final prefs = SPInstane<SharedPreferences>();
  final _reminderBox = Hive.box<Reminder>('reminders');

  List<Reminder> reminderList = [];

  List<Reminder> getReminders(String contactId) {
    reminderList = _reminderBox.values
        .where(
          (reminder) => reminder.contactId == contactId,
        ) // if you add `contactId` field in Transaction
        .toList();
    return reminderList;
  }


  Future<void> addReminder(Reminder reminder) async {
   await _reminderBox.add(reminder);
   reminderList = _reminderBox.values
       .where(
         (reminder) => reminder.contactId == reminder.contactId,
   ) // if you add `contactId` field in Transaction
       .toList();
   notifyListeners();
  }

   Future<void> removeReminder(int reminderID) async {
     final keyToDelete = _reminderBox.keys.firstWhere(
           (key) {
         final reminder = _reminderBox.get(key);
         return reminder?.reminderId == reminderID;
       },
       orElse: () => null,
     );

     if (keyToDelete != null) {
       await _reminderBox.delete(keyToDelete);
       reminderList.removeWhere((r) => r.reminderId == reminderID);
       notifyListeners();
     }
   }

}
