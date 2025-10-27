import 'dart:math';

import 'package:byaj_khata_book/core/constants/ContactType.dart';
import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:byaj_khata_book/widgets/SingleContactItem.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar, Colors, InputDecoration, InputBorder, TextField, AppBar, CircularProgressIndicator, Scaffold, InkWell, Icons, showDialog, TextButton, ElevatedButton, AlertDialog, MaterialPageRoute, IconButton;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants/RouteNames.dart';
import '../../core/utils/permission_handler.dart';
import '../../providers/TransactionProviderr.dart';
import '../../data/models/Contact.dart' as my_models;

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key, required this.isWithInterest});
  final bool isWithInterest;

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final Logger logger = Logger();
  String _searchQuery = '';
  List<my_models.Contact> _contacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  
  @override
  void initState() {
    super.initState();
    _checkAndRequestContactPermission();
  }

  Future<void> _checkAndRequestContactPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the centralized permission utility
      final permissionUtils = PermissionUtils();
      final hasPermission = await permissionUtils.requestContactsPermission(context);

      setState(() {
        _hasPermission = hasPermission;
      });

      if (hasPermission) {
        await _loadContacts();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error handling
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search contacts...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  void _addContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isWithInterest ? 'Add With Interest Contact' : 'Add New Contact',
          style: GoogleFonts.poppins(),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter contact name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (Optional)',
                    hintText: 'Enter mobile number (optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',style: GoogleFonts.poppins(
                color: AppColors.primaryColor
              ),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,     // 👈 Background color
                foregroundColor: Colors.white,    // 👈 Text (and icon) color
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // rounded corners
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                final phoneNumber = phoneController.text.trim();
                // Generate a unique ID for this contact using UUID if phone is empty
                final String contactId = phoneNumber.isEmpty ? 'contact_${widget.isWithInterest ? InterestType.withInterest.name : InterestType.withoutInterest.name}'
                    : "${phoneNumber}_${widget.isWithInterest ? InterestType.withInterest.name : InterestType.withoutInterest.name}";

                final transactionProvider = Provider.of<TransactionProviderr>(context, listen: false);

                // Check if contact with this ID already exists
                final existingContact = transactionProvider.getContactById(contactId);

                if (existingContact != null) {
                  // Contact already exists in the same tab we're trying to add to,
                  // just update the existing contact
                  Navigator.pop(context);
                  //
                  // final my_models.Contact contactData = my_models.Contact(
                  //   name: name,
                  //   contactId: contactId,
                  //   lastEditedAt: DateTime.now(),
                  //   interestType: widget.isWithInterest ? InterestType.withInterest : InterestType.withoutInterest,
                  //   displayPhone: phoneNumber.isEmpty ? 'No Phone' : phoneNumber,
                  //   initials: name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
                  //   colorValue:  Colors.primaries[name.length % Colors.primaries.length].value,
                  //   displayAmount: existingContact.displayAmount,
                  //   interestRate: widget.isWithInterest ? 12.0 : 0.0,
                  //   isGet: existingContact.isGet,
                  //   dayAgo: existingContact.dayAgo,
                  //   contactType: widget.isWithInterest ? ContactType.borrower  : ContactType.lender,
                  //   isNewContact: existingContact.isNewContact
                  // );
                  //
                  // transactionProvider.updateContact(contactData);
                  NavigateToContactDetailScreen(context, existingContact);
                  return;
                }

                Navigator.pop(context);

                // Create new contact data
                final my_models.Contact contactData = my_models.Contact(
                  contactId: contactId,
                  name: name,
                  displayPhone: phoneNumber.isEmpty ? 'No Phone' : phoneNumber,
                  initials: name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
                  colorValue:  Colors.primaries["Alice".length % Colors.primaries.length].value,
                  displayAmount: 0.0,
                  isGet: true,
                  dayAgo: 0,
                  isNewContact: true,
                  lastEditedAt: DateTime.now(),
                  interestType: widget.isWithInterest ? InterestType.withInterest : InterestType.withoutInterest,
                  interestRate: widget.isWithInterest ? 12.0 : 0.0,
                  contactType: widget.isWithInterest ? ContactType.borrower  : ContactType.lender,
                );
                // Add the contact
                transactionProvider.addContact(contactData);
                // Navigate to contact detail screen
                NavigateToContactDetailScreen(context, contactData);
              },
              child: Text('Next',style: GoogleFonts.poppins(
                color: Colors.white
              ),),
            ),
          ],
        );
      },
    );
  }

  void NavigateToContactDetailScreen(
      BuildContext context,
      my_models.Contact contact
      ) {
    context.push(
        RouteNames.contestDetails,
        extra: {
          'isWithInterest': widget.isWithInterest,
          'contactId': contact.contactId,
          'showSetupPrompt': false,
        }
    );
  }

  Widget _createNewContactButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: () {
          _addContactDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Create New Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withThumbnail: false,
      );

      final formattedContacts = contacts
          .where((contact) =>
      contact.displayName.isNotEmpty && contact.phones.isNotEmpty)
          .map((contact) {
        final phone = contact.phones.first.number.trim();

        return my_models.Contact(
          name: contact.displayName.trim(),
          contactId: "${phone}_${widget.isWithInterest ? InterestType.withInterest.name : InterestType.withoutInterest.name}",
          displayPhone: phone,
          initials: contact.displayName.isNotEmpty ? contact.displayName.substring(0, 1).toUpperCase() : "AA",
          interestType:widget.isWithInterest ? InterestType.withInterest : InterestType.withoutInterest ,
          isNewContact: true, // mark imported contacts
          lastEditedAt: DateTime.now(),
        );
      }).toList();
      // Sort by name
      formattedContacts.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _contacts = formattedContacts;
        _isLoading = false;
      });
    } catch (e) {
      // Removed debug print
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_accounts,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Contacts Permission Required',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please allow permission to access your contacts in the app settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();

              // Wait longer for settings to fully update
              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                // Check if permission was granted in settings
                final permissionStatus = await Permission.contacts.status;

                if (permissionStatus.isGranted) {
                  setState(() {
                    _hasPermission = true;
                  });

                  // Load contacts and refresh home screen
                  await _loadContacts();
                  // _refreshHomeScreen();

                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission granted! Loading contacts...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // Show an error message if permission is still denied
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission is still denied. Please grant contacts permission in settings.'),
                      duration: Duration(seconds: 3),
                    ),
                  );

                  // Recheck permission
                  _checkAndRequestContactPermission();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  List<my_models.Contact> get _contactsList {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts
        .where((contact) =>
    contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        contact.contactId.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildContactList() {
    return _contactsList.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: _contactsList.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final contact = _contactsList[index];
        return SingleContectItem(contact,context,widget.isWithInterest);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Disable the default back button
        automaticallyImplyLeading: false,
        // Custom leading widget
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white), // 👈 change icon & color
          onPressed: () {
            Navigator.pop(context); // or your own logic
          },
        ),
        title: Text(widget.isWithInterest ? 'Add With Interest Contact' : 'Add Contact' ,
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.white
          ),),
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _createNewContactButton(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                ? _buildPermissionDeniedView()
                : _buildContactList(),
          ),
        ],
      ),
    );
  }
}

