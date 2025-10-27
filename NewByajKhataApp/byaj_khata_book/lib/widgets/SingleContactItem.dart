import 'dart:math';

import 'package:byaj_khata_book/core/constants/ContactType.dart';
import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../core/constants/RouteNames.dart';
import '../data/models/Contact.dart' as my_model;
import '../data/models/Contact.dart';
import '../providers/TransactionProviderr.dart';

Widget SingleContectItem(
  my_model.Contact contact,
  BuildContext context,
  bool isWithInterest,
) {
  final logger = Logger();
  // Check if this contact already exists in the transaction provider
  final transactionProvider = Provider.of<TransactionProviderr>(
    context,
    listen: false,
  );
  final contactId = contact.contactId;
  final existingContact = transactionProvider.getContactById(contactId);
  final bool isContactExistingWithInterest =
      (existingContact != null &&
      existingContact.interestType == InterestType.withInterest);
  // For contacts from device, use a simpler display without transaction info
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: CircleAvatar(
      backgroundColor: Colors
          .primaries[contact.name.toString().length % Colors.primaries.length],
      child: Text(
        contact.name.toString().isNotEmpty
            ? contact.name.toString().substring(0, 1).toUpperCase()
            : '?',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    title: Text(
      contact.name,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    subtitle: Text(
      contact.displayPhone ?? '',
      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
    ),
    onTap: () {
      // Close select contact screen
      Navigator.pop(context);

      // Create a new contact and navigate to detail screen
      final name = contact.name;
      final phoneNo = contact.displayPhone ?? '';

      if (existingContact != null) {
        // If contact exists with interest type, respect that setting regardless of current tab
        if (isWithInterest == isContactExistingWithInterest) {
          // If we're in the With Interest tab and contact exists with interest, navigate to details
          _navigateToContactDetailsScreen(
            context,
            existingContact!,
            isWithInterest,
          );
          return;
        }
      } else {
        final Contact contactData = Contact(
          name: name,
          displayPhone: phoneNo,
          contactId: "${phoneNo}_${isWithInterest ? InterestType.withInterest.name : InterestType.withoutInterest.name}",
          initials: name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
          colorValue: Colors.primaries["Alice".length % Colors.primaries.length].value,
          displayAmount: 0.0,
          isGet: true,
          dayAgo: 0,
          interestType: isWithInterest ? InterestType.withInterest : InterestType.withoutInterest,
          interestRate: isWithInterest ? 12.0 : 0.0,
          contactType: ContactType.borrower,
          lastEditedAt: DateTime.now(),
          isNewContact: true,
        );

        // Get transaction provider to add this contact if it doesn't exist
        // transactionProvider.addContactIfNotExists(contactData);

        // Find the home screen state to refresh contacts
        _navigateToEditContactScreen(context, contactData, isWithInterest);
        logger.e("Navigating to edit screen with new contact: ${contactData.name} with isWithInterest: $isWithInterest");
      }
    },
  );
}

void _navigateToContactDetailsScreen(
  BuildContext context,
  Contact contact,
  bool isWithInterest,
) {
  context.push<Contact>(
    RouteNames.contestDetails,
    extra: {
      'isWithInterest': isWithInterest,
      'contactId': contact.contactId,
    }, // pass the contact as extra
  );
}


void _navigateToEditContactScreen(
  BuildContext context,
  Contact contact,
  bool isWithInterest,
) {
  context.push(
    RouteNames.editContact,
    extra: {
      'isWithInterest': isWithInterest,
      'contact': contact
    }
  );
}
