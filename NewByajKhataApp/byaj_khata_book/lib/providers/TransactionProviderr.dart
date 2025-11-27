import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../core/utils/HomeScreenEnum.dart';
import '../data/models/Contact.dart';
import '../data/models/Reminder.dart';
import '../data/models/Transaction.dart';

class TransactionProviderr extends ChangeNotifier {
  final _contactBox = Hive.box<Contact>('contacts');
  final _transactionBox = Hive.box<Transaction>('transactions');
  final _reminderBox = Hive.box<Reminder>('reminders');
  final logger = Logger();

  // List of contacts (stored separately from transactions)
  List<Contact> _contacts = [];

  // Get all contacts
  List<Contact> get contacts => _contacts;

  // Constructor
  TransactionProviderr() {
    // Changed to sequentially await each operation with single notification at the end
    _initializeProvider();
  }

  // New method for sequential initialization
  Future<void> _initializeProvider() async {
    try {
      // First attempt to load data
      await _loadData();
      // Set up a delayed reload to ensure data is fully loaded
      // This helps when the app is first launched and SharedPreferences might be slow
      Future.delayed(const Duration(milliseconds: 300), () {
        // Check if data loaded properly
        if (_contacts.isEmpty) {
          _loadData(notifyChanges: true);
        }

        // Always recalculate interest values to ensure they're up to date
        // _recalculateInterestValues();

        // Notify listeners again after everything is loaded
        notifyListeners();
      });
    } catch (e) {
      logger.e('Error initializing TransactionProvider: $e');

      // Attempt to reload data after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        _loadData(notifyChanges: true);
      });
    }
  }

  List<Contact> getFilteredAndSortedContacts({
    required bool isWithInterest,
    required FilterMode filterMode,
    required SortMode sortMode,
    String searchQuery = '',
  }) {
    // 1. Pick correct contacts
    List<Contact> contacts = _contacts
        .where(
          (c) =>
              (isWithInterest && c.interestType == InterestType.withInterest) ||
              (!isWithInterest &&
                  c.interestType == InterestType.withoutInterest),
        )
        .toList();

    //
    // logger.e("size of contacts: ${contacts.length}");
    // logger.e("contacts: $contacts");
    // 2. Apply search query
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      contacts = contacts.where((c) {
        final name = c.name.toLowerCase();
        final phone = c.contactId.toLowerCase();
        // final balance = calculateBalance(c.contactId).toString();
        final balance = calculateBalance(c.contactId).toString();
        return name.contains(lowerQuery) ||
            phone.contains(lowerQuery) ||
            balance.contains(lowerQuery);
      }).toList();
    }

    // 3. Apply filter mode
    if (filterMode != FilterMode.all) {
      contacts = contacts.where((c) {
        final balance = calculateBalance(c.contactId);
        if (filterMode == FilterMode.youReceived) {
          return balance > 0; // you will receive
        } else if (filterMode == FilterMode.youPaid) {
          return balance < 0; // you will pay
        }
        return true;
      }).toList();
    }

    // 4. Apply sorting
    switch (sortMode) {
      case SortMode.recent:
        contacts.sort((a, b) {
          final dateA = a.lastEditedAt ?? DateTime.now();
          final dateB = b.lastEditedAt ?? DateTime.now();
          return dateB.compareTo(dateA); // Newest first
        });
        break;

      case SortMode.highToLow:
        contacts.sort((a, b) {
          final amtA = calculateBalance(a.contactId);
          final amtB = calculateBalance(b.contactId);
          return amtB.compareTo(amtA);
        });
        break;

      case SortMode.lowToHigh:
        contacts.sort((a, b) {
          final amtA = calculateBalance(a.contactId);
          final amtB = calculateBalance(b.contactId);
          return amtA.compareTo(amtB);
        });
        break;

      case SortMode.byName:
        contacts.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return contacts;
  }

  Future<void> _loadData({bool notifyChanges = false}) async {
    try {
      // Load data in sequence
      await _loadContacts();
      // await _loadTransactions();
      // await _loadManualReminders();
      // await _ensureContactTransactionSynchronization(notifyChanges: false);
      // await _recalculateInterestValues();

      // Notify listeners only once if requested
      if (notifyChanges) {
        notifyListeners();
      } else {
        // Always notify at least once during initial load
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error loading data: $e');
      // Still notify listeners even if there was an error
      // This ensures the UI gets updated with whatever data was loaded
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String contactId, int index) async {
    try {
      final transactions = getTransactionsForContact(contactId);

      if (index >= 0 && index < transactions.length) {
        await transactions[index].delete(); // 🚀 simpler
        notifyListeners();
      }
    } catch (e) {
      logger.e("Error deleting transaction: $e");
    }
  }

  Future<void> addTransactionDetails(
    String contactId,
    double amount,
    String type,
    DateTime date,
    String note,
    List<String>? imagePath,
    bool isPrincipal, {
    double balanceAfterTx = 0.0,
  }) async {
    logger.e(
      "Adding transaction for $contactId: $amount, $type, $date, $note, $imagePath, $isPrincipal ",
    );
    final double positiveAmount = amount.abs();

    final tx = Transaction(
      date: date,
      amount: positiveAmount,
      note: note,
      imagePath: imagePath,
      contactId: contactId,
      transactionType: type,
      isInterestPayment: isPrincipal ? false : true,
      isPrincipal: isPrincipal,
      balanceAfterTx: balanceAfterTx,
    );
    await addTransaction(contactId, tx);
  }

  Future<void> updateTransaction(
    String contactId,
    int index,
    Transaction updatedTx,
  ) async {
    final txs = getTransactionsForContact(contactId);
    if (index < 0 || index >= txs.length) return;

    final existingTx = txs[index];

    existingTx.date = updatedTx.date;
    existingTx.amount = updatedTx.amount;
    existingTx.transactionType = updatedTx.transactionType;
    existingTx.note = updatedTx.note;
    existingTx.imagePath = updatedTx.imagePath;
    existingTx.isInterestPayment = updatedTx.isInterestPayment;
    existingTx.isPrincipal = updatedTx.isPrincipal;
    existingTx.interestRate = updatedTx.interestRate;

    await existingTx.save(); // persist in Hive

    // Update lastEditedAt in the associated contact
    final contact = _contactBox.get(contactId);
    if (contact != null) {
      contact.lastEditedAt = DateTime.now();
      await _contactBox.put(contactId, contact);
    }
    notifyListeners();
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      // 🔹 2. Delete the contact itself
      await _contactBox.delete(contactId);
      // 🔹 3. Refresh local contacts list
      _contacts = _contactBox.values.toList();
      // Delete associated transactions
      await deleteContactTransactions(contactId);
      // Delete entries from milk diary
      // await _cleanupMilkDiaryEntries(contactId);
      notifyListeners();
      return true;
    } catch (e) {
      // Log the error without using debug  logger.e
      return false;
    }
  }

  Future<void> deleteContactTransactions(String contactId) async {
    try {
      final txsToDelete = getTransactionsForContact(contactId);

      for (var tx in txsToDelete) {
        await tx.delete(); // because Transaction extends HiveObject
      }

      notifyListeners();
    } catch (e) {
      logger.e("Error deleting transactions for $contactId: $e");
    }
  }

  List<Transaction> getTransactionsForContact(String contactId) {
    return _transactionBox.values
        .where(
          (tx) => tx.contactId == contactId,
        ) // if you add `contactId` field in Transaction
        .toList();
  }

  double calculateBalance(String contactId) {
    double balance = 0;
    final transactions = getTransactionsForContact(contactId);
    if (transactions.isNotEmpty) {
      for (var tx in transactions) {
        final amount = tx.amount.abs(); // Already a double in model

        if (tx.transactionType == 'gave') {
          // If you GAVE money, it's a positive balance (you'll get it back)
          balance += amount;
        } else {
          // If you GOT mones a negative balance (you'll give it back)
          balance -= amount;
        }
      }
    } else {
      Contact? c = getContactById(contactId);
      if(c!=null) {
        if(c.isGet) balance = c.principal; else balance = -c.principal;
      }
    }
    logger.e("calculating balance $balance of id $contactId");
    return balance;
  }

  Contact? getContactById(String contactId) {
    try {
      final contact = _contactBox.get(contactId);
      if (contact != null) {
        logger.e('''
📘 fetched Contact:
------------------------
ID: ${contact.contactId}
Name: ${contact.name}
Phone: ${contact.displayPhone ?? 'N/A'}
Interest Rate: ${contact.interestRate} %
Interest Period: ${contact.interestPeriod}
Contact Type: ${contact.contactType}
Interest Type: ${contact.interestType}
Principal: ${contact.principal}
Interest Due: ${contact.interestDue}
Display Amount: ${contact.displayAmount}
Category: ${contact.category}
Color Value: ${contact.colorValue}
Initials: ${contact.initials}
Day Ago: ${contact.dayAgo}
Is Get: ${contact.isGet}
Is New Contact: ${contact.isNewContact}
Profile Image: ${contact.profileImage ?? 'N/A'}
Last Edited At: ${contact.lastEditedAt}
------------------------
''');
      }
      return contact;
    } catch (e) {
      logger.e("Error fetching contact $contactId: $e");
      return null;
    }
  }

  // 🔹 Update a contact
  Future<bool> updateContact(Contact updatedContact) async {
    try {
      await _contactBox.put(updatedContact.contactId, updatedContact);
      final contactAfterUpdate = getContactById(updatedContact.contactId);
      if (contactAfterUpdate != null) {
        logger.e('''
📘 Updated Contact:
------------------------
ID: ${contactAfterUpdate.contactId}
Name: ${contactAfterUpdate.name}
Phone: ${contactAfterUpdate.displayPhone ?? 'N/A'}
Interest Rate: ${contactAfterUpdate.interestRate} %
Interest Period: ${contactAfterUpdate.interestPeriod}
Contact Type: ${contactAfterUpdate.contactType}
Interest Type: ${contactAfterUpdate.interestType}
Principal: ${contactAfterUpdate.principal}
Interest Due: ${contactAfterUpdate.interestDue}
Display Amount: ${contactAfterUpdate.displayAmount}
Category: ${contactAfterUpdate.category}
Color Value: ${contactAfterUpdate.colorValue}
Initials: ${contactAfterUpdate.initials}
Day Ago: ${contactAfterUpdate.dayAgo}
Is Get: ${contactAfterUpdate.isGet}
Is New Contact: ${contactAfterUpdate.isNewContact}
Profile Image: ${contactAfterUpdate.profileImage ?? 'N/A'}
Last Edited At: ${contactAfterUpdate.lastEditedAt}
------------------------
''');
      }
      // await _loadContacts();
      // notifyListeners();
      return true;
    } catch (e) {
      logger.e("Error updating contact: $e");
      return false;
    }
  }

  // 🔹 Load all contacts from Hive
  Future<void> _loadContacts() async {
    try {
      _contacts = _contactBox.values.toList();
      logger.e("in Loaded contact the Number of contacts: ${_contacts.length}");
      for (var c in _contacts) {
        logger.e(
          '📦 Loaded from Hive: ${c.name}, interestRate=${c.interestRate}',
        );
      }
      notifyListeners();
    } catch (e) {
      logger.e("Error loading contacts: $e");
      _contacts = []; // fallback empty list
      notifyListeners();
    }
  }

  // ✅ Add a contact if it doesn’t already exist
  Future<bool> addContactIfNotExists(Contact newContact) async {
    try {
      final contactId = newContact.contactId;

      if (contactId.isEmpty) return false;

      // Check if this contact already exists
      final existingContact = _contactBox.get(contactId);
      if (existingContact != null) {
        bool hasChanges = false;

        // Compare updatable fields
        if (newContact.name != existingContact.name) {
          existingContact.name = newContact.name;
          hasChanges = true;
        }
        if (newContact.contactType != existingContact.contactType) {
          existingContact.contactType = newContact.contactType;
          hasChanges = true;
        }
        if (newContact.interestPeriod != existingContact.interestPeriod) {
          existingContact.interestPeriod = newContact.interestPeriod;
          hasChanges = true;
        }
        if (newContact.interestRate != existingContact.interestRate) {
          existingContact.interestRate = newContact.interestRate;
          hasChanges = true;
        }
        if (newContact.interestType != existingContact.interestType) {
          existingContact.interestType = newContact.interestType;
          hasChanges = true;
        }

        // Save updated contact if changed
        if (hasChanges) {
          await _contactBox.put(contactId, existingContact);
          await _loadContacts();
          notifyListeners();
        }

        return true;
      }

      // If contact doesn’t exist, save it
      await _contactBox.put(contactId, newContact);
      await _loadContacts();
      notifyListeners();

      return true;
    } catch (e) {
      logger.e("Error in addContactIfNotExists: $e");
      return false;
    }
  }

  // Add a contact
  Future<bool> addContact(Contact contact) async {
    try {
      logger.e('''
📘 adding new Contact:
------------------------
ID: ${contact.contactId}
Name: ${contact.name}
Phone: ${contact.displayPhone ?? 'N/A'}
Interest Rate: ${contact.interestRate} %
Interest Period: ${contact.interestPeriod}
Contact Type: ${contact.contactType}
Interest Type: ${contact.interestType}
Principal: ${contact.principal}
Interest Due: ${contact.interestDue}
Display Amount: ${contact.displayAmount}
Category: ${contact.category}
Color Value: ${contact.colorValue}
Initials: ${contact.initials}
Day Ago: ${contact.dayAgo}
Is Get: ${contact.isGet}
Is New Contact: ${contact.isNewContact}
Profile Image: ${contact.profileImage ?? 'N/A'}
Last Edited At: ${contact.lastEditedAt}
------------------------
''');
      await _contactBox.put(contact.contactId, contact);
      _contacts = _contactBox.values.toList();
      notifyListeners();
      return true;
    } catch (e) {
      logger.e("Error adding contact: $e");
      return false;
    }
  }

  // Add transaction
  Future<void> addTransaction(String contactId, Transaction tx) async {
    await _transactionBox.add(tx);
    notifyListeners();
  }
}
