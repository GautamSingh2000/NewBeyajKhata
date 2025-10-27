
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/AppColors.dart';
import '../data/models/Contact.dart';
import 'HomeScreenSingleContact.dart';

Widget homeScreenContactsList(
    List<Contact> dataList,
    String _searchQuery,
    bool _isWithInterest,
    ) {
  return Container(
    color: AppColors.backgroundColor,
    child: dataList.isEmpty
        ? Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 300)),
              builder: (context, snapshot) {
                if (dataList.isEmpty) {
                  // No contacts in the provider
                  return Column(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts added yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first contact with the button below',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                } else {
                  // We have contacts in the provider but none are showing
                  return Column(
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
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Try changing the tab or filter',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    )
        : ListView.builder(
      itemCount: dataList.length,
      padding: const EdgeInsets.only(bottom: 100), // For FAB clearance
      itemBuilder: (context, index) {
        final contact = dataList[index];
        return HomeScreenSingleContact(
          contact,
          context,
          _isWithInterest,
        );
      },
    ),
  );
}
