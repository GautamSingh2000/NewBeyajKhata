// import 'package:byaj_khata_book/screens/contacts/utils/ActionButtons.dart';
// import 'package:byaj_khata_book/screens/contacts/utils/SingleInterestDetailsColum.dart';
// import 'package:flutter/cupertino.dart';
//
// import '../../core/utils/FormatSmallCurrancy.dart';
// import '../../data/models/Contact.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:byaj_khata_book/core/constants/ContactType.dart';
// import 'package:byaj_khata_book/core/constants/InterestType.dart';
// import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
// import 'package:byaj_khata_book/data/models/Transaction.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../../core/constants/InterestPeriod.dart';
// import '../../core/constants/RouteNames.dart';
// import '../../core/theme/AppColors.dart';
// import '../../core/utils/StringUtils.dart';
// import '../../core/utils/image_picker_helper.dart';
// import '../../core/utils/permission_handler.dart';
// import '../../data/models/Contact.dart' as my_models;
// import '../../data/models/Contact.dart';
// import '../../providers/TransactionProviderr.dart';
// import '../../services/pdf_template_service.dart';
// import '../../widgets/ConfirmDialog.dart';
//
// class TransactionSummary extends StatefulWidget {
//   final String contactId;
//   const TransactionSummary({
//     super.key,
//     required this.contactId,});
//
//   @override
//   State<TransactionSummary> createState() => _TransactionSummaryState();
// }
//
// class _TransactionSummaryState extends State<TransactionSummary> {
//
//   bool _isSearching = false;
//   late TransactionProviderr _transactionProvider;
//   final ScrollController _scrollController = ScrollController();
//   bool _showScrollToTop = false;
//   bool _showScrollToBottom = false;
//   late my_models.Contact _contact;
//   final TextEditingController _searchController = TextEditingController();
//   final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
//   final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
//   String _contactId = '';
//   List<Transaction> _filteredTransactions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_scrollListener);
//     _searchController.addListener(_filterTransactions);
//     // Initialize contact ID
//     _contactId = widget.contactId;
//     final provider = Provider.of<TransactionProviderr>(context, listen: false);
//     final loadedContact = provider.getContactById(widget.contactId);
//     _contact = loadedContact! ;
//     // Show setup prompt for new contacts after a short delay
//     // if (widget.showSetupPrompt) {
//     //   WidgetsBinding.instance.addPostFrameCallback((_) {
//     //     _showSetupPrompt();
//     //   });
//     // }
//     //
//     // // Show transaction dialog if requested
//     // if (widget.showTransactionDialogOnLoad) {
//     //   WidgetsBinding.instance.addPostFrameCallback((_) {
//     //     _showAddTransactionDialog();
//     //   });
//     // }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryColor,
//         centerTitle: true,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         // Custom leading widget
//         leading: IconButton(
//           icon: SvgPicture.asset(
//             "assets/icons/left_icon.svg",
//             width: 20 ,
//             height: 20 ,
//             colorFilter: ColorFilter.mode(
//               Colors.white,
//               BlendMode.srcIn,
//             ),
//           ),
//           onPressed: () {
//             _onBackPressed(); // or your own logic
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onPressed: _showContactOptions,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // 🔹 Summary card
//               if (_contact.interestType == InterestType.withInterest)
//                 _buildInterestSummaryCard(_contact)
//               else
//                 _buildBasicSummaryCard(),
//
//               // 🔹 Transactions Header
//               Container(
//                 margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       offset: const Offset(0, 2),
//                       blurRadius: 5,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.receipt_long,
//                           size: 18,
//                           color: AppColors.primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'TRANSACTIONS',
//                           style: GoogleFonts.poppins(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         _isSearching ? Icons.close : Icons.search,
//                         size: 22,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _isSearching = !_isSearching;
//                           if (!_isSearching) _searchController.clear();
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//
//               // 🔹 Search Bar
//               if (_isSearching)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search transactions',
//                       prefixIcon: const Icon(Icons.search, size: 20),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       fillColor: Colors.white,
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//               // 🔹 Transaction Header Row
//               transactionHeaderRow(context),
//
//               // 🔹 Expanded List (RecyclerView)
//               Expanded(
//                 child: _filteredTransactions.isEmpty
//                     ? const Center(child: Text('No transactions found'))
//                     : ListView.builder(
//                   controller: _scrollController,
//                   physics: const BouncingScrollPhysics(),
//                   padding: const EdgeInsets.only(bottom: 150),
//                   itemCount: _filteredTransactions.length,
//                   itemBuilder: (context, index) {
//                     final tx = _filteredTransactions[index];
//                     // final runningBalance = _calculateRunningBalance(
//                     //   index,
//                     // );
//                     final bool isWithInterest =
//                         _contact.interestType ==
//                             InterestType.withInterest;
//                     // double runningBalance;
//
//                     if (isWithInterest) {
//                       // Recompute current principal from saved contact principal minus principal repayments
//                       final allTx = _transactionProvider
//                           .getTransactionsForContact(_contactId);
//
//                       double totalPrincipalPaid = 0.0;
//                       for (var t in allTx) {
//                         if (t.isPrincipal == true) {
//                           // repayment direction depends on contact type
//                           if (_contact.contactType ==
//                               ContactType.borrower) {
//                             // contact is borrower -> they owe you
//                             // when you 'got' money from them (transactionType == 'got'), it's repayment
//                             if (t.transactionType == 'got')
//                               totalPrincipalPaid += t.amount;
//                           } else {
//                             // contact is lender -> you owe them
//                             // when you 'gave' money to them (transactionType == 'gave'), it's repayment
//                             if (t.transactionType == 'gave')
//                               totalPrincipalPaid += t.amount;
//                           }
//                         }
//                       }
//
//                       final double currentPrincipal =
//                       (_contact.principal - totalPrincipalPaid).clamp(
//                         0,
//                         double.infinity,
//                       );
//
//                       // Use contact.interestDue (make sure interestDue is updated when you add/edit tx)
//                       final double interestDue = _contact.interestDue;
//
//                       // runningBalance = currentPrincipal + interestDue;
//                     } else {
//                       // non-interest contacts: keep previous running logic
//                       // runningBalance = _calculateRunningBalance(index);
//                     }
//                     return _buildTransactionItem(tx);
//                   },
//                 ),
//               ),
//             ],
//           ),
//
//           // 🔹 Scroll to Top Button
//           if (_showScrollToTop)
//             Positioned(
//               bottom: 100,
//               right: 20,
//               child: FloatingActionButton(
//                 mini: true,
//                 backgroundColor: AppColors.blue0001.withAlpha(80),
//                 onPressed: () {
//                   _scrollController.animateTo(
//                     0,
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeOut,
//                   );
//                 },
//                 child: const Icon(Icons.arrow_upward, color: Colors.white),
//               ),
//             ),
//
//           // 🔹 Scroll to Bottom Button
//           if (_showScrollToBottom)
//             Positioned(
//               bottom: 20,
//               right: 20,
//               child: FloatingActionButton(
//                 mini: true,
//                 backgroundColor: AppColors.blue0001.withAlpha(80),
//                 onPressed: () {
//                   _scrollController.animateTo(
//                     _scrollController.position.maxScrollExtent,
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeOut,
//                   );
//                 },
//                 child: const Icon(Icons.arrow_downward, color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//       bottomNavigationBar: BottomAppBar(
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                         8,
//                       ), // 👈 rounded corners
//                     ),
//                   ),
//                   onPressed: () => _addTransaction('gave'),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(Icons.arrow_drop_up, size: 25, color: Colors.white),
//                       SizedBox(width: 8),
//                       Text(
//                         'I GAVE',
//                         style: GoogleFonts.poppins(color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                         8,
//                       ), // 👈 rounded corners
//                     ),
//                   ),
//                   onPressed: () => _addTransaction('got'),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.arrow_drop_down,
//                         size: 25,
//                         color: Colors.white,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         'I Receive',
//                         style: GoogleFonts.poppins(color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _addTransaction(String type) {
//     final TextEditingController amountController = TextEditingController();
//     final TextEditingController noteController = TextEditingController();
//     DateTime selectedDate = DateTime.now();
//     String? imagePath;
//     String? amountError; // Add this to track error state
//     // Define maximum amount (99 crore)
//     const double maxAmount = 990000000.0;
//     double currentBalance = _contact.principal;
//
//     // Check if this is a with-interest contact
//     final ContactType relationshipType = _contact.contactType;
//
//     // Default to principal amount
//     bool isPrincipalAmount = true;
//
//     // Determine if we should show the interest option based on relationship and transaction type
//     final bool showInterestOption = _contact.interestType == InterestType.withInterest;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: SingleChildScrollView(
//             child: Container(
//               color: Colors.white,
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Bottom sheet drag handle
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 4,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   // Header
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         backgroundColor: type == 'gave'
//                             ? Colors.red.shade100
//                             : Colors.green.shade100,
//                         radius: 14,
//                         child: SvgPicture.asset(
//                           type == 'gave'
//                               ? "assets/icons/arrow_up.svg"
//                               : "assets/icons/arrow_down.svg",
//                           width: 20,
//                           height: 20,
//                           colorFilter: ColorFilter.mode(
//                             type == 'gave' ? Colors.red : Colors.green,
//                             BlendMode.srcIn,
//                           ),
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         type == 'gave' ? 'Paid' : 'Received',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: type == 'gave' ? Colors.red : Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Amount Field
//                   Text(
//                     'Amount',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: amountController,
//                           keyboardType: const TextInputType.numberWithOptions(
//                             decimal: true,
//                           ),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(
//                               RegExp(r'^\d+\.?\d{0,2}'),
//                             ),
//                           ],
//                           decoration: InputDecoration(
//                             hintText: '0.00',
//                             filled: true,
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                 color: AppColors.primaryColor,
//                                 // color when focused
//                                 width: 1.5,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade400,
//                                 // color when not focused
//                                 width: 1,
//                               ),
//                             ),
//                             fillColor: Colors.grey.shade100,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 12,
//                             ),
//                             prefixText: '₹ ',
//                             errorText: amountError,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Date selection now appears directly to the right of amount
//                       GestureDetector(
//                         onTap: () async {
//                           final DateTime? picked = await showDatePicker(
//                             context: context,
//                             initialDate: selectedDate,
//                             firstDate: DateTime(2000),
//                             lastDate: DateTime.now(),
//                             builder: (context, child) {
//                               return Theme(
//                                 data: Theme.of(context).copyWith(
//                                   colorScheme: ColorScheme.light(
//                                     primary: type == 'gave'
//                                         ? Colors.red
//                                         : Colors.green,
//                                   ),
//                                 ),
//                                 child: child!,
//                               );
//                             },
//                           );
//                           if (picked != null && picked != selectedDate) {
//                             setState(() {
//                               selectedDate = picked;
//                             });
//                           }
//                         },
//                         child: Container(
//                           height: 48,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: Colors.grey.shade400,
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               SvgPicture.asset(
//                                 "assets/icons/calendar.svg",
//                                 width: 22,
//                                 height: 22,
//                                 colorFilter: ColorFilter.mode(
//                                   type == 'gave' ? Colors.red : Colors.green,
//                                   BlendMode.srcIn,
//                                 ),
//                                 fit: BoxFit.contain,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 dateFormat.format(selectedDate).split(',')[0],
//                                 style: GoogleFonts.poppins(fontSize: 14),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 12),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         flex: 3, // 1.5x when compared to 2x below
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Note Field
//                               Text(
//                                 'Note (optional)',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               TextField(
//                                 controller: noteController,
//                                 decoration: InputDecoration(
//                                   hintText: 'Add a note...',
//                                   filled: true,
//                                   fillColor: Colors.grey.shade100,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide(
//                                       color: AppColors.primaryColor,
//                                       // color when focused
//                                       width: 1.5,
//                                     ),
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade400,
//                                       // color when not focused
//                                       width: 1,
//                                     ),
//                                   ),
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         flex: 2, // 1.5x when compared to 2x below
//                         child: Align(
//                           alignment: Alignment.topLeft,
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Image Upload
//                               Text(
//                                 'Receipt (optional)',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               GestureDetector(
//                                 onTap: () {
//                                   _showImageSourceOptions(context, (path) {
//                                     setState(() {
//                                       imagePath = path;
//                                     });
//                                   });
//                                 },
//                                 child: Container(
//                                   height: 80,
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade100,
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: imagePath != null
//                                         ? Border.all(
//                                       color: Colors.grey.shade400,
//                                       width: 1,
//                                     )
//                                         : null,
//                                   ),
//                                   child: imagePath != null
//                                       ? Stack(
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius:
//                                         BorderRadius.circular(6),
//                                         child: Image.file(
//                                           File(imagePath!),
//                                           width: double.infinity,
//                                           height: double.infinity,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                       Positioned(
//                                         top: 4,
//                                         right: 4,
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               imagePath = null;
//                                             });
//                                           },
//                                           child: Container(
//                                             padding: const EdgeInsets.all(
//                                               2,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.black
//                                                   .withOpacity(0.6),
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: const Icon(
//                                               Icons.close,
//                                               color: Colors.white,
//                                               size: 14,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   )
//                                       : Column(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.add_photo_alternate,
//                                         size: 24,
//                                         color: type == 'gave'
//                                             ? Colors.red.withOpacity(0.7)
//                                             : Colors.green.withOpacity(
//                                           0.7,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         'Add receipt',
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 10,
//                                           color: type == 'gave'
//                                               ? Colors.red.withOpacity(
//                                             0.7,
//                                           )
//                                               : Colors.green.withOpacity(
//                                             0.7,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   // Principal/Interest Switch (Only for with-interest contacts when appropriate)
//                   if (showInterestOption) ...[
//                     const SizedBox(height: 12),
//                     if ((relationshipType == ContactType.borrower &&
//                         type == 'got') ||
//                         (relationshipType == ContactType.lender &&
//                             type == 'gave')) ...[
//                       Text(
//                         'Is this amount for:',
//                         style: GoogleFonts.poppins(
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildSelectionButton(
//                             title: 'Interest',
//                             isSelected: !isPrincipalAmount,
//                             icon: "assets/icons/selected_sip.svg",
//                             color: Colors.amber.shade700,
//                             onTap: () {
//                               setState(() {
//                                 isPrincipalAmount = false;
//                               });
//                             },
//                           ),
//                           const SizedBox(width: 8),
//                           _buildSelectionButton(
//                             title: 'Principal',
//                             isSelected: isPrincipalAmount,
//                             icon: "assets/icons/money_icon.svg",
//                             color: Colors.blue,
//                             onTap: () {
//                               setState(() {
//                                 isPrincipalAmount = true;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                     // actualIsPrincipal = true;
//                   ],
//                   const SizedBox(height: 12),
//
//                   // Action Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: TextButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             foregroundColor: Colors.grey[700],
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             'Cancel',
//                             style: GoogleFonts.poppins(fontSize: 14),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (amountController.text.isEmpty) {
//                               setState(() {
//                                 amountError = 'Amount is required';
//                               });
//                               return;
//                             }
//                             final amount = double.tryParse(
//                               amountController.text,
//                             );
//                             if (amount == null || amount <= 0) {
//                               setState(() {
//                                 amountError = 'Please enter a valid amount';
//                               });
//                               return;
//                             }
//
//                             // Validate maximum amount
//                             if (amount > maxAmount) {
//                               setState(() {
//                                 amountError =
//                                 'Maximum allowed amount is ₹99 cr';
//                               });
//                               return;
//                             }
//
//                             // Create transaction note
//                             String note = noteController.text.isNotEmpty
//                                 ? noteController.text
//                                 : (type == 'gave'
//                                 ? 'Payment sent'
//                                 : 'Payment received');
//
//                             // Add prefix for interest/principal if applicable
//                             if (showInterestOption) {
//                               String prefix = isPrincipalAmount
//                                   ? 'Principal: '
//                                   : 'Interest: ';
//                               note = prefix + note;
//                             }
//
//                             // Update balance after this transaction
//                             if (_contact.contactType == ContactType.borrower) {
//                               // Borrower owes you
//                               if (type == 'gave') {
//                                 currentBalance += amount; // You lent more
//                               } else if (type == 'got') {
//                                 currentBalance -= amount; // They repaid
//                               }
//                             } else {
//                               // Lender - You owe them
//                               if (type == 'gave') {
//                                 currentBalance -= amount; // You repaid
//                               } else if (type == 'got') {
//                                 currentBalance += amount; // You borrowed
//                               }
//                             }
//                             // ✅ Corrected logic for isGet
//                             if (currentBalance < 0 &&
//                                 _contact.contactType == ContactType.lender) {
//                               _contact.contactType = ContactType.borrower;
//                               currentBalance = currentBalance.abs();
//                               var logger = new Logger();
//                               logger.e("currentBalance $currentBalance");
//                               _contact.isGet = true;
//                             } else if (currentBalance < 0 &&
//                                 _contact.contactType == ContactType.borrower) {
//                               _contact.contactType = ContactType.lender;
//                               currentBalance = currentBalance.abs();
//                               var logger = new Logger();
//                               logger.e("currentBalance $currentBalance");
//                               _contact.isGet = false;
//                             }
//                             // Add transaction details
//                             _transactionProvider.addTransactionDetails(
//                               _contactId,
//                               amount,
//                               type,
//                               selectedDate,
//                               note,
//                               imagePath,
//                               isPrincipalAmount,
//                               balanceAfterTx: currentBalance,
//                             );
//                             _contact.principal = currentBalance;
//                             _contact.displayAmount = currentBalance;
//
//                             // Save updated contact
//                             _transactionProvider.updateContact(_contact);
//
//                             // Refresh transactions
//                             setState(() {
//                               _filterTransactions();
//                             });
//
//                             Navigator.pop(context);
//
//                             // Show success message
//                             final String amountType = isPrincipalAmount
//                                 ? 'principal'
//                                 : 'interest';
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'Added ${type == 'gave' ? 'payment' : 'receipt'} of ${currencyFormat.format(amount)} for $amountType',
//                                 ),
//                                 duration: const Duration(seconds: 2),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: type == 'gave'
//                                 ? Colors.red
//                                 : Colors.green,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             'Save',
//                             style: GoogleFonts.poppins(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showImageSourceOptions(
//       BuildContext context,
//       Function(String) onImageSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Select Image Source',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildImageSourceOption(
//                   context,
//                   Icons.camera_alt,
//                   'Camera',
//                       () => _getImage(ImageSource.camera, onImageSelected),
//                 ),
//                 _buildImageSourceOption(
//                   context,
//                   Icons.photo_library,
//                   'Gallery',
//                       () => _getImage(ImageSource.gallery, onImageSelected),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageSourceOption(
//       BuildContext context,
//       IconData icon,
//       String label,
//       VoidCallback onTap,
//       ) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
//             child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSelectionButton({
//     required String title,
//     required bool isSelected,
//     required String icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
//           decoration: BoxDecoration(
//             color: isSelected ? color.withOpacity(0.1) : Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: isSelected ? color : Colors.grey.shade300,
//               width: isSelected ? 2 : 1,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SvgPicture.asset(
//                 icon,
//                 width: 18,
//                 height: 18,
//                 colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: GoogleFonts.poppins(
//                   fontSize: 10,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   color: isSelected ? color : Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _getImage(
//       ImageSource source,
//       Function(String) onImageSelected,
//       ) async {
//     final imagePickerHelper = ImagePickerHelper();
//
//     try {
//       // Use our helper that handles permission automatically
//       final imageFile = await imagePickerHelper.pickImage(context, source);
//
//       if (imageFile != null) {
//         onImageSelected(imageFile.path);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: $e')));
//       }
//     }
//   }
//
//
//   void _editTransaction(Transaction tx, int originalIndex) {
//     if (originalIndex == -1) return;
//
//     final TextEditingController amountController = TextEditingController(
//       // text: tx['amount'].toString()
//       text: tx.amount.toString(),
//     );
//     final TextEditingController noteController = TextEditingController(
//       text: tx.note,
//       // text: tx['note'] ?? ''
//     );
//
//     // String type = tx['type'] ?? 'gave';
//     // DateTime selectedDate = tx['date'] ?? DateTime.now();
//     // String? imagePath = tx['imagePath'];
//     String type = tx.transactionType;
//     DateTime selectedDate = tx.date;
//     String? imagePath = tx.imagePath;
//     String? amountError; // Add this to track error state
//
//     // Define maximum amount (99 crore)
//     const double maxAmount = 990000000.0;
//
//     // Check if this is a with-interest contact
//     // final bool isWithInterest = _contact['type'] != null;
//     // final String relationshipType = widget.contact['type'] as String? ?? '';
//     final bool isWithInterest =
//         _contact.interestType == InterestType.withInterest;
//     final ContactType relationshipType = _contact.contactType;
//
//     // Determine if it's a principal or interest transaction
//     bool isPrincipalAmount = true;
//     // if (isWithInterest && tx['isPrincipal'] != null) {
//     if (isWithInterest && tx.isPrincipal != null) {
//       // isPrincipalAmount = tx['isPrincipal'] as bool;
//       isPrincipalAmount = tx.isPrincipal;
//     } else if (isWithInterest) {
//       // Check the note for clues
//       // final note = (tx['note'] ?? '').toLowerCase();
//       final note = (tx.note ?? '').toLowerCase();
//       isPrincipalAmount = !note.contains('interest:');
//     }
//
//     // Determine if we should show the interest option based on relationship and transaction type
//     final bool showInterestOption =
//         isWithInterest &&
//             !(
//                 // (relationshipType == 'borrower' && type == 'gave') || // Borrowers don't receive interest
//                 //     (relationshipType == 'lender' && type == 'got')
//                 (relationshipType == ContactType.borrower &&
//                     type == 'gave') || // Borrowers don't receive interest
//                     (relationshipType == ContactType.lender &&
//                         type == 'got') // Lenders don't pay interest
//             );
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: SingleChildScrollView(
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Bottom sheet drag handle
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 4,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   // Header
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         backgroundColor: type == 'gave'
//                             ? Colors.red.shade100
//                             : Colors.green.shade100,
//                         radius: 16,
//                         child: Icon(
//                           type == 'gave'
//                               ? Icons.arrow_upward
//                               : Icons.arrow_downward,
//                           color: type == 'gave' ? Colors.red : Colors.green,
//                           size: 16,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Edit ${type == 'gave' ? 'Payment' : 'Receipt'}',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: type == 'gave' ? Colors.red : Colors.green,
//                         ),
//                       ),
//                       const Spacer(),
//                       // Delete button
//                       IconButton(
//                         icon: const Icon(
//                           Icons.delete_outline,
//                           color: Colors.red,
//                           size: 22,
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _confirmDeleteTransaction(tx, originalIndex);
//                         },
//                         tooltip: 'Delete transaction',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Amount Field
//                   Text(
//                     'Amount',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: amountController,
//                           keyboardType: const TextInputType.numberWithOptions(
//                             decimal: true,
//                           ),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(
//                               RegExp(r'^\d+\.?\d{0,2}'),
//                             ),
//                           ],
//                           decoration: InputDecoration(
//                             hintText: '0.00',
//                             filled: true,
//                             fillColor: Colors.grey.shade100,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 12,
//                             ),
//                             prefixText: '₹ ',
//                             errorText: amountError,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Date selection now appears directly to the right of amount
//                       GestureDetector(
//                         onTap: () async {
//                           final DateTime? picked = await showDatePicker(
//                             context: context,
//                             initialDate: selectedDate,
//                             firstDate: DateTime(2000),
//                             lastDate: DateTime.now(),
//                             builder: (context, child) {
//                               return Theme(
//                                 data: Theme.of(context).copyWith(
//                                   colorScheme: ColorScheme.light(
//                                     primary: type == 'gave'
//                                         ? Colors.red
//                                         : Colors.green,
//                                   ),
//                                 ),
//                                 child: child!,
//                               );
//                             },
//                           );
//                           if (picked != null && picked != selectedDate) {
//                             setState(() {
//                               selectedDate = picked;
//                             });
//                           }
//                         },
//                         child: Container(
//                           height: 48,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.calendar_today,
//                                 size: 14,
//                                 color: type == 'gave'
//                                     ? Colors.red
//                                     : Colors.green,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 dateFormat.format(selectedDate).split(',')[0],
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 3, // 1.5x when compared to 2x below
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: Column(
//                             children: [
//                               // Note Field
//                               Text(
//                                 'Note (optional)',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                               TextField(
//                                 controller: noteController,
//                                 decoration: InputDecoration(
//                                   hintText: 'Add a note...',
//                                   filled: true,
//                                   fillColor: Colors.grey.shade100,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         flex: 1, // 1.5x when compared to 2x below
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: Column(
//                             children: [
//                               // Image Upload
//                               Text(
//                                 'Attach Receipt/Bill (optional)',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               GestureDetector(
//                                 onTap: () {
//                                   _showImageSourceOptions(context, (path) {
//                                     setState(() {
//                                       imagePath = path;
//                                     });
//                                   });
//                                 },
//                                 child: Container(
//                                   height: 80,
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade100,
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: imagePath != null
//                                         ? Border.all(
//                                       color: type == 'gave'
//                                           ? Colors.red
//                                           : Colors.green,
//                                       width: 1,
//                                     )
//                                         : null,
//                                   ),
//                                   child: imagePath != null
//                                       ? Stack(
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius:
//                                         BorderRadius.circular(6),
//                                         child: Image.file(
//                                           File(imagePath!),
//                                           width: double.infinity,
//                                           height: double.infinity,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                       Positioned(
//                                         top: 4,
//                                         right: 4,
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               imagePath = null;
//                                             });
//                                           },
//                                           child: Container(
//                                             padding: const EdgeInsets.all(
//                                               2,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.black
//                                                   .withOpacity(0.6),
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: const Icon(
//                                               Icons.close,
//                                               color: Colors.white,
//                                               size: 14,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   )
//                                       : Column(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.add_photo_alternate,
//                                         size: 24,
//                                         color: type == 'gave'
//                                             ? Colors.red.withOpacity(0.7)
//                                             : Colors.green.withOpacity(
//                                           0.7,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         'Tap to add photo',
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 12,
//                                           color: type == 'gave'
//                                               ? Colors.red.withOpacity(
//                                             0.7,
//                                           )
//                                               : Colors.green.withOpacity(
//                                             0.7,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   // const SizedBox(height: 12),
//                   const SizedBox(height: 16),
//
//                   // Principal/Interest Switch (Only for with-interest contacts when appropriate)
//                   if (showInterestOption) ...[
//                     const SizedBox(height: 12),
//                     Text(
//                       'Is this amount for:',
//                       style: GoogleFonts.poppins(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildSelectionButton(
//                           title: 'Interest',
//                           isSelected: !isPrincipalAmount,
//                           icon: "assets/icons/selected_sip_icon.svg",
//                           color: Colors.amber.shade700,
//                           onTap: () {
//                             setState(() {
//                               isPrincipalAmount = false;
//                             });
//                           },
//                         ),
//                         const SizedBox(width: 8),
//                         _buildSelectionButton(
//                           title: 'Principal',
//                           isSelected: isPrincipalAmount,
//                           icon: "assets/icons/money_icon.svg",
//                           color: Colors.blue,
//                           onTap: () {
//                             setState(() {
//                               isPrincipalAmount = true;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                   const SizedBox(height: 12),
//
//                   // Transaction Type Toggle Button
//                   Text(
//                     'Transaction Type',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             setState(() {
//                               type = 'gave';
//                               // Recalculate whether to show interest option
//                               if (relationshipType == 'borrower') {
//                                 // If switching to gave for a borrower, force principal and hide option
//                                 isPrincipalAmount = true;
//                               }
//                             });
//                           },
//                           icon: const Icon(Icons.arrow_upward, size: 14),
//                           label: Text(
//                             'PAID',
//                             style: GoogleFonts.poppins(fontSize: 12),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: type == 'gave'
//                                 ? Colors.red
//                                 : Colors.grey.shade300,
//                             foregroundColor: type == 'gave'
//                                 ? Colors.white
//                                 : Colors.black54,
//                             elevation: type == 'gave' ? 1 : 0,
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             setState(() {
//                               type = 'got';
//                               // Recalculate whether to show interest option
//                               if (relationshipType == 'lender') {
//                                 // If switching to got for a lender, force principal and hide option
//                                 isPrincipalAmount = true;
//                               }
//                             });
//                           },
//                           icon: const Icon(Icons.arrow_downward, size: 14),
//                           label: Text(
//                             'RECEIVED',
//                             style: GoogleFonts.poppins(fontSize: 12),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: type == 'got'
//                                 ? Colors.green
//                                 : Colors.grey.shade300,
//                             foregroundColor: type == 'got'
//                                 ? Colors.white
//                                 : Colors.black54,
//                             elevation: type == 'got' ? 1 : 0,
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Action Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: TextButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             foregroundColor: Colors.grey[700],
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             'Cancel',
//                             style: GoogleFonts.poppins(fontSize: 16),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (amountController.text.isEmpty) {
//                               setState(() {
//                                 amountError = 'Amount is required';
//                               });
//                               return;
//                             }
//
//                             final amount = double.tryParse(
//                               amountController.text,
//                             );
//                             if (amount == null || amount <= 0) {
//                               setState(() {
//                                 amountError = 'Please enter a valid amount';
//                               });
//                               return;
//                             }
//
//                             // Validate maximum amount
//                             if (amount > maxAmount) {
//                               setState(() {
//                                 amountError =
//                                 'Maximum allowed amount is ₹99 cr';
//                               });
//                               return;
//                             }
//
//                             // Ensure that certain relationship/transaction combinations are forced to principal
//                             bool actualIsPrincipal = isPrincipalAmount;
//                             if ((relationshipType == 'borrower' &&
//                                 type == 'gave') ||
//                                 (relationshipType == 'lender' &&
//                                     type == 'got')) {
//                               actualIsPrincipal = true;
//                             }
//
//                             // Create updated transaction note
//                             String note = noteController.text.isNotEmpty
//                                 ? noteController.text
//                                 : (type == 'gave'
//                                 ? 'Payment sent'
//                                 : 'Payment received');
//
//                             // Add prefix for interest/principal if applicable
//                             if (isWithInterest) {
//                               String prefix = actualIsPrincipal
//                                   ? 'Principal: '
//                                   : 'Interest: ';
//                               // If note doesn't already have the prefix, add it
//                               if (!note.startsWith(prefix) &&
//                                   !note.startsWith('Principal:') &&
//                                   !note.startsWith('Interest:')) {
//                                 note = prefix + note;
//                               } else if ((actualIsPrincipal &&
//                                   note.startsWith('Interest:')) ||
//                                   (!actualIsPrincipal &&
//                                       note.startsWith('Principal:'))) {
//                                 // If the prefix doesn't match the selection, update it
//                                 note =
//                                     prefix +
//                                         note
//                                             .substring(note.indexOf(':') + 1)
//                                             .trim();
//                               }
//                             }
//
//                             final updatedTx = Transaction(
//                               date: selectedDate,
//                               amount: amount,
//                               transactionType: type,
//                               note: note,
//                               imagePath: imagePath,
//                               isInterestPayment: false,
//                               // or set true if user marks it
//                               contactId: _contactId,
//                               isPrincipal: isWithInterest
//                                   ? actualIsPrincipal
//                                   : false,
//                               interestRate: isWithInterest
//                                   ? _contact.interestRate
//                                   : null,
//                             );
//
//                             // Update the transaction
//                             _transactionProvider.updateTransaction(
//                               _contactId,
//                               originalIndex,
//                               updatedTx,
//                             );
//
//                             // Refresh the UI
//                             setState(() {
//                               _filterTransactions();
//                             });
//
//                             Navigator.pop(context);
//
//                             // Show success message
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   'Transaction updated successfully',
//                                 ),
//                                 duration: Duration(seconds: 2),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: type == 'gave'
//                                 ? Colors.red
//                                 : Colors.green,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             'Save Changes',
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _confirmDeleteTransaction(Transaction tx, int originalIndex) {
//     if (originalIndex == -1) return;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Transaction'),
//           content: Text(
//             'Are you sure you want to delete this transaction? This cannot be undone.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//
//                 // Delete the transaction
//                 _transactionProvider.deleteTransaction(
//                   _contactId,
//                   originalIndex,
//                 );
//
//                 // Show a snackbar
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Transaction deleted'),
//                     action: SnackBarAction(
//                       label: 'UNDO',
//                       onPressed: () {
//                         // Re-add the deleted transaction
//                         _transactionProvider.addTransaction(_contactId, tx);
//                         // _loadTransactions();
//                         _filterTransactions();
//                       },
//                     ),
//                   ),
//                 );
//
//                 // Refresh the transactions list
//                 // _loadTransactions();
//                 _filterTransactions();
//
//                 // Update the contact data
//                 setState(() {
//                   _loadContact();
//                 });
//               },
//               child: Text(
//                 'Delete',
//                 style: GoogleFonts.poppins(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildTransactionItem(Transaction tx) {
//     final isGave = tx.transactionType == 'gave';
//     final hasImage = tx.imagePath != null && tx.imagePath!.isNotEmpty;
//     final date = DateFormat("dd MMM yy").format(tx.date);
//     final time = DateFormat("hh:mm a").format(tx.date);
//
//     final allTransactions = _transactionProvider.getTransactionsForContact(
//       _contactId,
//     );
//     final originalIndex = allTransactions.indexOf(tx);
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final scale = screenWidth / 400; // responsive scaling
//
//     return GestureDetector(
//       onTap: () => _editTransaction(tx, originalIndex),
//       onLongPress: () => _confirmDeleteTransaction(tx, originalIndex),
//       child: Card(
//         margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
//         elevation: 2,
//         color: Colors.white,
//         shadowColor: Colors.black.withOpacity(0.05),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(0),
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//             ),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ===== TOP ROW (weighted) =====
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // LEFT: Date + Time + Type (2 weight)
//                   Expanded(
//                     flex: 3,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         SvgPicture.asset(
//                           isGave
//                               ? "assets/icons/arrow_up.svg"
//                               : "assets/icons/arrow_down.svg",
//                           width: 14 * scale,
//                           height: 14 * scale,
//                           colorFilter: ColorFilter.mode(
//                             isGave ? Colors.red : Colors.green,
//                             BlendMode.srcIn,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               date,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12 * scale,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 1),
//                             Text(
//                               time,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 9 * scale,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                             const SizedBox(height: 1),
//                             Text(
//                               isGave ? "Payment sent" : "Payment received",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 9 * scale,
//                                 color: Colors.grey.shade600,
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildVerticalDivider(),
//                   // RIGHT: Debit (1) | Credit (1) | Balance (1)
//                   // Debit
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: isGave
//                           ? Text(
//                         formatSmallCurrency(tx.amount),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12 * scale,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.red,
//                         ),
//                       )
//                           : const SizedBox(),
//                     ),
//                   ),
//
//                   _buildVerticalDivider(),
//                   // Credit
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: !isGave
//                           ? Text(
//                         formatSmallCurrency(tx.amount),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12 * scale,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.green,
//                         ),
//                       )
//                           : const SizedBox(),
//                     ),
//                   ),
//
//                   _buildVerticalDivider(),
//                   // Balance
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.centerRight,
//                       child: Text(
//                         formatSmallCurrency(tx.balanceAfterTx),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12 * scale,
//                           fontWeight: FontWeight.w600,
//                           color: tx.balanceAfterTx >= 0
//                               ? Colors.green
//                               : Colors.red,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // ===== NOTE + RECEIPT =====
//               if (tx.note.isNotEmpty || hasImage) ...[
//                 const SizedBox(height: 8),
//                 if (tx.note.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 14),
//                     child: Text(
//                       tx.note.length > 10
//                           ? '${tx.note.substring(0, 10)}...'
//                           : tx.note,
//                       style: GoogleFonts.poppins(
//                         fontSize: 10 * scale,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                 if (hasImage)
//                   GestureDetector(
//                     onTap: () => _showFullImage(context, tx.imagePath!),
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Row(
//                         children: [
//                           SvgPicture.asset(
//                             "assets/icons/receit_icon.svg",
//                             width: 12,
//                             height: 12,
//                             colorFilter: ColorFilter.mode(
//                               AppColors.blue0001,
//                               BlendMode.srcIn,
//                             ),
//                             fit: BoxFit.contain,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'View Receipt',
//                             style: GoogleFonts.poppins(
//                               color: AppColors.blue0001,
//                               fontSize: 11 * scale,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showFullImage(BuildContext context, String imagePath) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AppBar(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               title: Text('Receipt'),
//               leading: IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             Container(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.6,
//               ),
//               child: Image.file(File(imagePath), fit: BoxFit.contain),
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showContactOptions() async {
//     final result = await context.push<Contact>(
//       RouteNames.editContact,
//         extra: {
//           'contact': _contact, // pass the contact as extra
//           'isCreatingContact': false
//         }
//     );
//
//     if (result == true) {
//       // Refresh the screen if contact was updated or deleted
//       setState(() {
//         _loadContact();
//       });
//     }
//   }
//
//   void _onBackPressed() {
//     ScaffoldMessenger.of(
//       context,
//     ).clearSnackBars(); // ✅ Safe because widget is still active
//     Navigator.pop(context);
//   }
//
//   void _scrollListener() {
//     if (!_scrollController.hasClients) return;
//
//     final position = _scrollController.position;
//     final isAtTop = position.pixels <= 50;
//     final isAtBottom = position.pixels >= position.maxScrollExtent - 50;
//
//     setState(() {
//       _showScrollToTop = !isAtTop;
//       _showScrollToBottom = !isAtBottom;
//     });
//   }
//
//   void _filterTransactions() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       final transactions = _transactionProvider.getTransactionsForContact(
//         _contactId,
//       );
//
//       // First filter the transactions
//       if (query.isEmpty) {
//         _filteredTransactions = List.from(transactions);
//       } else {
//         _filteredTransactions = transactions.where((tx) {
//           return tx.note.toLowerCase().contains(query) || // note is String
//               tx.amount.toString().contains(query); // amount is double
//         }).toList();
//       }
//
//       // Then sort them by date, newest first
//       _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
//     });
//   }
//
//   Widget _buildBasicSummaryCard() {
//     final balance = _calculateBalance();
//     final isPositive = balance >= 0;
//     // Choose colors based on balance status
//     final Color primaryColor = isPositive
//         ? Colors.green.shade700
//         : Colors.red.shade700;
//     final Color secondaryColor = isPositive
//         ? Colors.green.shade400
//         : Colors.red.shade400;
//     final Color lightColor = isPositive
//         ? Colors.green.shade50
//         : Colors.red.shade50;
//
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: primaryColor.withOpacity(0.2),
//             offset: const Offset(0, 4),
//             blurRadius: 12,
//           ),
//         ],
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [primaryColor, secondaryColor],
//         ),
//       ),
//       child: Column(
//         children: [
//           // Main balance section
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with label and info button
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           isPositive
//                               ? Icons.account_balance_wallet
//                               : Icons.payments,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           isPositive ? 'You Will RECEIVE' : 'You Will PAY',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                     GestureDetector(
//                       onTap: _showContactInfo,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Icon(
//                           Icons.info_outline,
//                           size: 16,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Balance amount with currency
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Rs. ',
//                       style: GoogleFonts.poppins(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Expanded(
//                       child: Text(
//                         NumberFormat('#,##,##0.00').format(balance.abs()),
//                         style: const TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // Last updated info
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text(
//                       'Last updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 11,
//                         color: Colors.white.withOpacity(0.8),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // Statistics section
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.9),
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(16),
//                 bottomRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 actionButtonCompact(
//                   context,
//                   Icons.call,
//                   'Call',
//                   Colors.blue,
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
//                   ),
//                   onTap: _handleCallButton,
//                 ),
//                 actionButtonCompact(
//                   context,
//                   Icons.picture_as_pdf,
//                   'PDF Report',
//                   Colors.red,
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFFE57373), Color(0xFFC62828)],
//                   ),
//                   onTap: _handlePdfReport,
//                 ),
//                 actionButtonCompact(
//                   context,
//                   Icons.notifications,
//                   'Reminder',
//                   Colors.orange,
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
//                   ),
//                   onTap: _setReminder,
//                 ),
//                 actionButtonCompact(
//                   context,
//                   Icons.sms,
//                   'SMS',
//                   Colors.green,
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
//                   ),
//                   onTap: _handleSmsButton,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget transactionHeaderRow(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final scale = screenWidth / 400;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         border: Border(
//           bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//         ),
//       ),
//       child: Row(
//         children: [
//           // 🕓 DATE COLUMN (1.5x)
//           Expanded(
//             flex: 3, // 1.5x when compared to 2x below
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "Date",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12 * scale,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//             ),
//           ),
//           _buildVerticalDivider(),
//           // 💸 DEBIT (1x)
//           Expanded(
//             flex: 2,
//             child: Align(
//               alignment: Alignment.center,
//               child: Text(
//                 "Debit",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12 * scale,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.red,
//                 ),
//               ),
//             ),
//           ),
//
//           _buildVerticalDivider(),
//           // 💰 CREDIT (1x)
//           Expanded(
//             flex: 2,
//             child: Align(
//               alignment: Alignment.center,
//               child: Text(
//                 "Credit",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12 * scale,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.green,
//                 ),
//               ),
//             ),
//           ),
//
//           _buildVerticalDivider(),
//           // 🧾 BALANCE (1x)
//           Expanded(
//             flex: 2,
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 "Balance",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12 * scale,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.blue0001,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVerticalDivider() {
//     return Container(
//       height: 18,
//       width: 1,
//       color: Colors.grey.shade300,
//       margin: const EdgeInsets.symmetric(horizontal: 0),
//     );
//   }
//
//   Widget _buildInterestSummaryCard(Contact contact) {
//     final transactions = _transactionProvider.getTransactionsForContact(
//       _contactId,
//     );
//
//     // Base values from Contact model
//     double principal = contact.principal; // Saved principal
//     double interestPaid = 0.0;
//     double accumulatedInterest = 0.0;
//     DateTime? firstTransactionDate;
//     DateTime? lastInterestCalculationDate;
//
//     // Sort transactions chronologically
//     transactions.sort((a, b) => a.date.compareTo(b.date));
//
//     final relationshipType = contact.contactType;
//     final isBorrower = relationshipType == ContactType.borrower;
//
//     if (transactions.isNotEmpty) {
//       firstTransactionDate = transactions.first.date;
//       lastInterestCalculationDate = firstTransactionDate;
//
//       for (var tx in transactions) {
//         final amount = tx.amount;
//         final isGave = tx.transactionType == 'gave';
//         final txDate = tx.date;
//         final note = (tx.note).toLowerCase();
//
//         // --- INTEREST PAYMENT TRACKING ---
//         if (tx.isInterestPayment) {
//           interestPaid += amount;
//         }
//
//         // --- INTEREST ACCRUAL CALCULATION ---
//         if (lastInterestCalculationDate != null && principal > 0) {
//           final daysSinceLast = txDate
//               .difference(lastInterestCalculationDate)
//               .inDays;
//           if (daysSinceLast > 0) {
//             final interestRate = contact.interestRate;
//             final isMonthly = contact.interestPeriod == InterestPeriod.monthly;
//             double interestForPeriod = 0.0;
//
//             int completeMonths = 0;
//             DateTime tempDate = lastInterestCalculationDate;
//             while (true) {
//               DateTime nextMonth = DateTime(
//                 tempDate.year,
//                 tempDate.month + 1,
//                 tempDate.day,
//               );
//               if (nextMonth.isAfter(txDate)) break;
//               completeMonths++;
//               tempDate = nextMonth;
//             }
//
//             if (isMonthly) {
//               if (completeMonths > 0) {
//                 interestForPeriod +=
//                     principal * (interestRate / 100) * completeMonths;
//               }
//               final remainingDays = txDate.difference(tempDate).inDays;
//               if (remainingDays > 0) {
//                 final daysInMonth = DateTime(
//                   tempDate.year,
//                   tempDate.month + 1,
//                   0,
//                 ).day;
//                 final monthProportion = remainingDays / daysInMonth;
//                 interestForPeriod +=
//                     principal * (interestRate / 100) * monthProportion;
//               }
//             } else {
//               // Yearly rate converted to monthly
//               final monthlyRate = interestRate / 12;
//               if (completeMonths > 0) {
//                 interestForPeriod +=
//                     principal * (monthlyRate / 100) * completeMonths;
//               }
//               final remainingDays = txDate.difference(tempDate).inDays;
//               if (remainingDays > 0) {
//                 final daysInMonth = DateTime(
//                   tempDate.year,
//                   tempDate.month + 1,
//                   0,
//                 ).day;
//                 final monthProportion = remainingDays / daysInMonth;
//                 interestForPeriod +=
//                     principal * (monthlyRate / 100) * monthProportion;
//               }
//             }
//
//             accumulatedInterest += interestForPeriod;
//           }
//         }
//
//         // --- HANDLE EXPLICIT INTEREST PAYMENTS (NOTES) ---
//         if (note.contains('interest:')) {
//           if (isGave && isBorrower) {
//             // Borrower paid interest → reduce accumulated interest
//             accumulatedInterest = (accumulatedInterest - amount).clamp(
//               0,
//               double.infinity,
//             );
//           } else if (!isGave && !isBorrower) {
//             // Lender received interest → reduce accumulated interest
//             accumulatedInterest = (accumulatedInterest - amount).clamp(
//               0,
//               double.infinity,
//             );
//           } else {
//             interestPaid += amount;
//           }
//         }
//
//         lastInterestCalculationDate = txDate;
//       }
//     }
//
//     double currentPrincipal = contact.principal;
//
//     // --- INTEREST UNTIL TODAY ---
//     double interestDue = accumulatedInterest;
//     if (lastInterestCalculationDate != null && currentPrincipal > 0) {
//       final interestRate = contact.interestRate;
//       final isMonthly = contact.interestPeriod == InterestPeriod.monthly;
//       double interestFromLastTx = 0.0;
//       DateTime now = DateTime.now();
//
//       int completeMonths = 0;
//       DateTime tempDate = lastInterestCalculationDate;
//       while (true) {
//         DateTime nextMonth = DateTime(
//           tempDate.year,
//           tempDate.month + 1,
//           tempDate.day,
//         );
//         if (nextMonth.isAfter(now)) break;
//         completeMonths++;
//         tempDate = nextMonth;
//       }
//
//       if (isMonthly) {
//         if (completeMonths > 0) {
//           interestFromLastTx +=
//               currentPrincipal * (interestRate / 100) * completeMonths;
//         }
//         final remainingDays = now.difference(tempDate).inDays;
//         if (remainingDays > 0) {
//           final daysInMonth = DateTime(
//             tempDate.year,
//             tempDate.month + 1,
//             0,
//           ).day;
//           final monthProportion = remainingDays / daysInMonth;
//           interestFromLastTx +=
//               currentPrincipal * (interestRate / 100) * monthProportion;
//         }
//       } else {
//         final monthlyRate = interestRate / 12;
//         if (completeMonths > 0) {
//           interestFromLastTx +=
//               currentPrincipal * (monthlyRate / 100) * completeMonths;
//         }
//         final remainingDays = now.difference(tempDate).inDays;
//         if (remainingDays > 0) {
//           final daysInMonth = DateTime(
//             tempDate.year,
//             tempDate.month + 1,
//             0,
//           ).day;
//           final monthProportion = remainingDays / daysInMonth;
//           interestFromLastTx +=
//               currentPrincipal * (monthlyRate / 100) * monthProportion;
//         }
//       }
//
//       interestDue += interestFromLastTx;
//     }
//
//     // --- NET INTEREST AFTER PAYMENTS ---
//     interestDue = max(0, interestDue - interestPaid);
//     contact.interestDue = interestDue;
//
//     // --- DAILY INTEREST ---
//     final rate = contact.interestRate;
//     final isMonthly = contact.interestPeriod == InterestPeriod.monthly;
//     double monthlyInterest = isMonthly
//         ? currentPrincipal * (rate / 100)
//         : currentPrincipal * ((rate / 12) / 100);
//
//     final now = DateTime.now();
//     final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
//     double interestPerDay = monthlyInterest / daysInMonth;
//
//     // --- TOTAL DUE ---
//     final totalAmount = currentPrincipal + interestDue;
//
//     final Color relationshipColor = relationshipType == ContactType.borrower
//         ? const Color(0xFF5D69E3)
//         : const Color(0xFF2E9E7A);
//
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             relationshipColor.withOpacity(0.9),
//             relationshipColor.withOpacity(0.7),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: relationshipColor.withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.only(top:12, bottom: 12, left: 12, right:12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.4),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: SvgPicture.asset(
//                         relationshipType == ContactType.borrower
//                             ? "assets/icons/wallet_filled.svg"
//                             : "assets/icons/balance_icon.svg",
//                         width: 18,
//                         height: 18,
//                         colorFilter: const ColorFilter.mode(
//                           Colors.white,
//                           BlendMode.srcIn,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Interest Summary',
//                       style: GoogleFonts.poppins(
//                         fontSize: context.screenHeight * 0.018,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.only(left: 8.0),
//                       child: Text(
//                         '${_contact.interestRate} % ${_contact.interestPeriod == InterestPeriod.monthly ? 'P.M.' : 'P.A.'}',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: _showContactInfo,
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.info_outline,
//                       size: 14,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       flex: 1,
//                       child: singleInterestDetailsColum(
//                         title: 'Principal',
//                         amount: currentPrincipal.toString(),
//                         icon: "assets/icons/rupee_icon.svg",
//                         alignStart: true, // 👈 added
//                       ),
//                     ),
//                     Container(
//                       margin: EdgeInsets.symmetric(horizontal: 10.0),
//                       height: 50,
//                       width: 1,
//                       color: Colors.white.withOpacity(0.3),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: singleInterestDetailsColum(
//                         title: 'Interest Due',
//                         amount: interestDue.toString(),
//                         icon: "assets/icons/interest_icon.svg",
//                         alignStart: true, // 👈 added
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
//                 Container(
//                   padding: EdgeInsets.symmetric(vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: singleInterestDetailsColum(
//                     title: 'Total :',
//                     // icon: "assets/icons/total_amount_icon.svg",
//                     amount: totalAmount.toString(),
//                     showBgShape: false,
//                     titleSize: 14,
//                     amountSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//
//             // --- Action Buttons ---
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.9),
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(16),
//                   bottomRight: Radius.circular(16),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   actionButtonCompact(
//                     context,
//                     Icons.call,
//                     'Call',
//                     Colors.blue,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     onTap: _handleCallButton,
//                   ),
//                   actionButtonCompact(
//                     context,
//                     Icons.picture_as_pdf,
//                     'PDF Report',
//                     Colors.red,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFE57373), Color(0xFFC62828)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     onTap: _handlePdfReport,
//                   ),
//                   actionButtonCompact(
//                     context,
//                     Icons.notifications,
//                     'Reminder',
//                     Colors.orange,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     onTap: _setReminder,
//                   ),
//                   actionButtonCompact(
//                     context,
//                     Icons.sms,
//                     'SMS',
//                     Colors.green,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     onTap: _handleSmsButton,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showContactInfo() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           // keeps it tight to content
//           children: [
//             Text(
//               _contact.name,
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInfoRow(
//               'Phone',
//               _contact.displayPhone ?? _contact.name,
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               'Category',
//               StringUtils.capitalizeFirstLetter(_contact.category),
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow('Account Type', _contact.interestType == InterestType.withoutInterest ? 'No Interest': "With Interest"),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Close',
//               style: GoogleFonts.poppins(color: AppColors.primaryColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           '$label:',
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.grey,
//           ),
//         ),
//         Text(value),
//       ],
//     );
//   }
//
//   // Calculate total balance
//   double _calculateBalance() {
//     return _transactionProvider.calculateBalance(_contactId);
//   }
//
//   void _handleCallButton() async {
//     final phone = _contact.displayPhone;
//
//     if (phone == null || phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No phone number available for this contact'),
//         ),
//       );
//       return;
//     }
//
//     // Check phone call permission first
//     final permissionUtils = PermissionUtils();
//     final hasCallPermission = await permissionUtils.requestCallPhonePermission(
//       context,
//     );
//
//     if (!hasCallPermission) {
//       // Permission denied
//       return;
//     }
//
//     // Format phone number (remove spaces and special characters)
//     final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
//
//     try {
//       // Use direct intent URL that bypasses the confirmation dialog
//       // First try using the tel: scheme with external application mode
//       bool launched = await launchUrl(
//         Uri.parse('tel:$formattedPhone'),
//         mode: LaunchMode.externalNonBrowserApplication,
//       );
//
//       // If the above didn't work, try alternate approach
//       if (!launched) {
//         await launchUrl(
//           Uri.parse('tel:$formattedPhone'),
//           mode: LaunchMode.externalApplication,
//         );
//       }
//     } catch (e) {
//       // Show error message if dialer can't be opened
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open phone dialer')),
//         );
//       }
//     }
//   }
//
//   void _handlePdfReport() async {
//     try {
//       // Show loading indicator
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Generating PDF report...')),
//         );
//       }
//       // Get transactions
//       final transactions = _transactionProvider.getTransactionsForContact(_contactId,);
//
//       // Prepare data for PDF summary card
//       final balance = _calculateBalance();
//       final isPositive = balance >= 0;
//       bool isWithInterest = _contact.interestType == InterestType.withInterest;
//
//       // Create a more detailed summary with contact information
//       final List<Map<String, dynamic>> summaryItems = [
//         {'label': 'Name:', 'value': _contact.name},
//         {
//           'label': 'Phone:',
//           'value': _contact.displayPhone ?? _contact.contactId,
//         },
//         {
//           'label': isPositive ? 'YOU WILL GET' : 'YOU WILL GIVE',
//           'value': 'Rs. ${PdfTemplateService.formatCurrency(balance.abs())}',
//           'highlight': true,
//           'isPositive': isPositive,
//         },
//       ];
//
//       // Add interest information if applicable
//       if (isWithInterest) {
//         final contactType = _contact.contactType ;
//         final interestRate = _contact.interestRate;
//         final isMonthly = _contact.interestPeriod == InterestPeriod.monthly;
//
//         summaryItems.addAll([
//           {
//             'label': 'Interest Rate:',
//             'value': '$interestRate% ${isMonthly ? 'per month' : 'per annum'}',
//           },
//           {
//             'label': 'Relationship:',
//             'value':
//             '${StringUtils.capitalizeFirstLetter(contactType.toString())} (${contactType == ContactType.borrower ? 'They borrow from you' : 'You borrow from them'})',
//           },
//         ]);
//
//         // Calculate interest values
//         if (transactions.isNotEmpty) {
//           // Calculate principal and interest amounts
//           double principalAmount = _contact.principal;
//
//           // // Calculate based on current balance and interest rate
//           // principalAmount = balance.abs(); // Use the balance as principal for simplicity
//
//           // Calculate monthly interest
//           double monthlyInterest = _contact.interestDue;
//           if (isMonthly) {
//             monthlyInterest = principalAmount * (interestRate / 100);
//           } else {
//             // Convert annual rate to monthly
//             double monthlyRate = interestRate / 12;
//             monthlyInterest = principalAmount * (monthlyRate / 100);
//           }
//
//           // Calculate daily interest based on days in current month
//           final daysInMonth = DateTime(
//             DateTime.now().year,
//             DateTime.now().month + 1,
//             0,
//           ).day;
//
//           summaryItems.addAll([
//             {
//               'label': 'Estimated Principal:',
//               'value':
//               'Rs. ${PdfTemplateService.formatCurrency(principalAmount)}',
//             },
//             {
//               'label': 'Est. Monthly Interest:',
//               'value':
//               'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest)}',
//             },
//             {
//               'label': 'Est. Daily Interest:',
//               'value':
//               'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest / daysInMonth)}',
//             },
//           ]);
//         }
//       }
//
//       // Add transaction stats
//       if (transactions.isNotEmpty) {
//         final totalPaid = transactions
//             .where((tx) => tx.transactionType == 'gave')
//             .fold(0.0, (sum, tx) => sum + (tx.amount));
//
//         final totalReceived = transactions
//             .where((tx) => tx.transactionType == 'got')
//             .fold(0.0, (sum, tx) => sum + (tx.amount));
//
//         final earliestDate = transactions
//             .map((tx) => tx.date as DateTime)
//             .reduce((a, b) => a.isBefore(b) ? a : b);
//
//         final latestDate = transactions
//             .map((tx) => tx.date as DateTime)
//             .reduce((a, b) => a.isAfter(b) ? a : b);
//
//         summaryItems.addAll([
//           {'label': 'Total Transactions:', 'value': '${transactions.length}'},
//           {
//             'label': 'Total Paid:',
//             'value': 'Rs. ${PdfTemplateService.formatCurrency(totalPaid)}',
//           },
//           {
//             'label': 'Total Received:',
//             'value': 'Rs. ${PdfTemplateService.formatCurrency(totalReceived)}',
//           },
//           {
//             'label': 'First Transaction:',
//             'value': DateFormat('dd MMM yyyy').format(earliestDate),
//           },
//           {
//             'label': 'Latest Transaction:',
//             'value': DateFormat('dd MMM yyyy').format(latestDate),
//           },
//         ]);
//       }
//
//       // Prepare data for transaction table
//       final List<String> tableColumns = ['Date', 'Note', 'Amount', 'Type'];
//       final List<List<String>> tableRows = [];
//
//       // Sort transactions by date (newest first)
//       final sortedTransactions = List<Transaction>.from(transactions);
//       sortedTransactions.sort(
//             (a, b) => (b.date ).compareTo(a.date ),
//       );
//
//       for (var transaction in sortedTransactions) {
//         final date =  DateFormat('dd MMM yyyy').format(transaction.date);
//
//         String note = transaction.note ?? '';
//         if (note.isEmpty) {
//           note = transaction.transactionType == 'gave'
//               ? 'Payment sent'
//               : 'Payment received';
//         }
//
//         final amount =
//             'Rs. ${PdfTemplateService.formatCurrency(transaction.amount)}';
//         final type = transaction.transactionType == 'gave'
//             ? 'You Paid'
//             : 'You Received';
//
//         tableRows.add([date, note, amount, type]);
//       }
//
//       // Create PDF content
//       final content = [
//         // Contact Summary Section
//         PdfTemplateService.buildSummaryCard(
//           title: 'Contact Summary',
//           items: summaryItems,
//         ),
//         pw.SizedBox(height: 20),
//
//         // Transaction Table
//         PdfTemplateService.buildDataTable(
//           title: 'Transaction History',
//           columns: tableColumns,
//           rows: tableRows,
//           columnWidths: {
//             0: const pw.FlexColumnWidth(2), // Date
//             1: const pw.FlexColumnWidth(3), // Note
//             2: const pw.FlexColumnWidth(1.5), // Amount
//             3: const pw.FlexColumnWidth(1.5), // Type
//           },
//         ),
//       ];
//
//       // Generate the PDF document
//       final contactName = _contact.name
//           .toString()
//           .replaceAll(RegExp(r'[^\w\s]+'), '')
//           .replaceAll(' ', '_');
//       final date = DateFormat('yyyy_MM_dd').format(DateTime.now());
//       final timestamp = DateFormat('HH_mm_ss').format(DateTime.now());
//       final random =
//           DateTime.now().millisecondsSinceEpoch % 10000; // Add random component
//       final fileName = '${contactName}_report_${date}_${timestamp}_$random.pdf';
//
//       final pdf = await PdfTemplateService.createDocument(
//         title: _contact.name,
//         subtitle: 'Transaction Report',
//         content: content,
//         metadata: {
//           'keywords':
//           'transaction, report, ${_contact.name}, balance, my byaj book',
//         },
//       );
//
//       // Save and open the PDF
//       await PdfTemplateService.saveAndOpenPdf(pdf, fileName);
//
//       // Show success message
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('PDF report generated successfully'),
//                 Text(
//                   'Filename: $fileName',
//                   style: const TextStyle(fontSize: 12, color: Colors.white70),
//                 ),
//               ],
//             ),
//             duration: const Duration(seconds: 3),
//             action: SnackBarAction(
//               label: 'OK',
//               onPressed: () {
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
//               },
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       // Show error message
//       final logger = new Logger();
//       logger.e("error while creating pdf $e");
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error generating PDF report: $e'),
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     }
//   }
//
//   void _setReminder() async {
//     // Check if there's already an active reminder for this contact
//     final existingReminder = await _checkForExistingReminder();
//
//     if (existingReminder != null) {
//       // Show dialog with options to view, cancel or create new reminder
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Reminder Already Exists'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'You already have a reminder set for ${_contact.name} on:',
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 DateFormat(
//                   'dd MMM yyyy',
//                 ).format(existingReminder['scheduledDate']),
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _cancelReminder(existingReminder['id']);
//               },
//               child: Text('Cancel Reminder'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Keep It'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _showDateTimePickerForReminder();
//               },
//               child: Text('Set New Reminder'),
//             ),
//           ],
//         ),
//       );
//       return;
//     }
//
//     // No existing reminder, show date picker directly
//     _showDateTimePickerForReminder();
//   }
//
//   Future<Map<String, dynamic>?> _checkForExistingReminder() async {
//     final prefs = await SharedPreferences.getInstance();
//     final remindersJson = prefs.getStringList('contact_reminders') ?? [];
//
//     for (final reminderJson in remindersJson) {
//       try {
//         final reminder = jsonDecode(reminderJson);
//         if (reminder['contactId'] == _contact.displayPhone) {
//           final scheduledDate = DateTime.parse(reminder['scheduledDate']);
//           // Only return if the reminder is in the future
//           if (scheduledDate.isAfter(DateTime.now())) {
//             return reminder;
//           }
//         }
//       } catch (e) {
//         print('Error parsing reminder: $e');
//       }
//     }
//     return null;
//   }
//
//   Future<void> _cancelReminder(int id) async {
//     // Cancel the notification
//     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//     await flutterLocalNotificationsPlugin.cancel(id);
//
//     // Remove from shared preferences
//     final prefs = await SharedPreferences.getInstance();
//     final remindersJson = prefs.getStringList('contact_reminders') ?? [];
//
//     final updatedReminders = remindersJson.where((reminderJson) {
//       try {
//         final reminder = jsonDecode(reminderJson);
//         return reminder['id'] != id;
//       } catch (e) {
//         return true; // Keep entries that can't be parsed
//       }
//     }).toList();
//
//     await prefs.setStringList('contact_reminders', updatedReminders);
//
//     // Show confirmation
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Reminder cancelled'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   void _showDateTimePickerForReminder() async {
//     final DateTime? selectedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//
//     if (selectedDate != null && mounted) {
//       // Create a DateTime with just the date component (set time to start of day)
//       final scheduledDate = DateTime(
//         selectedDate.year,
//         selectedDate.month,
//         selectedDate.day,
//       );
//
//       // Create a unique ID for this notification based on contact and time
//       final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
//
//       // Generate reminder text
//       final balance = _calculateBalance();
//       final isCredit = balance >= 0;
//       final String reminderText = isCredit
//           ? "Reminder to collect ${currencyFormat.format(balance.abs())} from ${_contact.name}"
//           : "Reminder to pay ${currencyFormat.format(balance.abs())} to ${_contact.name}";
//
//       // Schedule the notification
//       await _scheduleNotification(
//         id: notificationId,
//         title: "Payment Reminder",
//         body: reminderText,
//         scheduledDate: scheduledDate,
//       );
//
//       // Store reminder details in shared preferences
//       await _saveReminderDetails(notificationId, scheduledDate, reminderText);
//
//       // Show confirmation to user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}',
//             ),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _saveReminderDetails(
//       int id,
//       DateTime scheduledDate,
//       String message,
//       ) async {
//     final prefs = await SharedPreferences.getInstance();
//     final remindersJson = prefs.getStringList('contact_reminders') ?? [];
//
//     // Create reminder object
//     final reminder = {
//       'id': id,
//       'contactId': _contact.contactId,
//       'contactName': _contact.name,
//       'scheduledDate': scheduledDate.toIso8601String(),
//       'message': message,
//       'createdAt': DateTime.now().toIso8601String(),
//     };
//
//     // Add to list
//     remindersJson.add(jsonEncode(reminder));
//
//     // Save updated list
//     await prefs.setStringList('contact_reminders', remindersJson);
//
//     // Also notify the NotificationProvider to update UI
//     if (mounted) {
//       // Add to notification center
//       // final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
//       // notificationProvider.addContactReminderNotification(
//       //   contactId: _contact['phone'],
//       //   contactName: _contact['name'],
//       //   amount: _calculateBalance().abs(),
//       //   dueDate: scheduledDate,
//       //   paymentType: _calculateBalance() >= 0 ? 'collect' : 'pay',
//       // );
//     }
//   }
//
//   Future<void> _scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledDate,
//   }) async {
//     // Access the global notification plugin
//     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//     // Create notification details
//     const androidDetails = AndroidNotificationDetails(
//       'payment_reminders',
//       'Payment Reminders',
//       channelDescription: 'Notifications for payment reminders',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     );
//
//     const iosDetails = DarwinNotificationDetails();
//
//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     // Show an immediate notification as confirmation
//     await flutterLocalNotificationsPlugin.show(
//       id + 1000, // Use different ID for confirmation notification
//       "Reminder Scheduled",
//       "Payment reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}",
//       notificationDetails,
//     );
//
//     // For actual scheduled notifications, we'll just store the information
//     // and rely on the immediate notification for now as a simplification
//     // This avoids timezone and scheduling complexities
//
//     // Show a message to the user about the scheduled reminder
//     print('Notification scheduled for: ${scheduledDate.toString()}');
//   }
//
//   void _handleSmsButton() async {
//     final balance = _calculateBalance();
//     final isPositive = balance >= 0;
//
//     final message =
//     '''
// Dear ${_contact.name},
//
// 🙏 *Payment Reminder*
//
// This is a gentle reminder regarding your account with My Byaj Book:
//
// 💰 *Account Summary:*
// Current balance: ${currencyFormat.format(balance.abs())}
// ${isPositive ? '➡️ Payment due to be received' : '➡️ Payment to be made'}
//
// ${isPositive ? '✅ Kindly arrange the payment at your earliest convenience.' : '✅ I will arrange the payment shortly.'}
//
// Thank you for your attention to this matter.
//
// Best regards,
// ${_getAppUserName()} 📱
// ''';
//
//     bool whatsappOpened = await _tryOpenWhatsApp(message);
//
//     if (!whatsappOpened) {
//       await _trySendSMS(message);
//     }
//   }
//
//   Future<bool> _tryOpenWhatsApp(String message) async {
//     final phone = _contact.contactId;
//     if (phone == null || phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No phone number available for this contact'),
//         ),
//       );
//       return false;
//     }
//
//     // Just get a clean number with no spaces or special chars
//     final formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
//
//     // For India, make sure we have 91 prefix for proper WhatsApp opening
//     String whatsappPhone = formattedPhone;
//     if (formattedPhone.length == 10) {
//       whatsappPhone = "91$formattedPhone";
//     }
//
//     // Create the URL
//     final whatsappUrl = Uri.parse(
//       'whatsapp://send?phone=$whatsappPhone&text=${Uri.encodeComponent(message)}',
//     );
//
//     try {
//       // Launch directly with explicit mode setting
//       await launchUrl(
//         whatsappUrl,
//         mode: LaunchMode.externalNonBrowserApplication,
//       );
//       return true;
//     } catch (e) {
//       print('Error opening WhatsApp: $e');
//       // WhatsApp not installed or couldn't be launched
//       return false;
//     }
//   }
//
//   Future<void> _trySendSMS(String message) async {
//     final phone = _contact.contactId;
//     if (phone == null || phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No phone number available for this contact'),
//         ),
//       );
//       return;
//     }
//
//     // No longer need SMS permission - using intent instead
//     // final permissionUtils = PermissionUtils();
//     // final hasSmsPermission = await permissionUtils.requestSmsPermission(context);
//
//     // if (!hasSmsPermission) {
//     //   // Permission denied
//     //   return;
//     // }
//
//     // For SMS, keep the + prefix for international numbers
//     String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
//
//     // Create SMS URL
//     final smsUrl = Uri.parse(
//       'sms:$formattedPhone?body=${Uri.encodeComponent(message)}',
//     );
//
//     try {
//       // Launch directly without checking canLaunchUrl first
//       await launchUrl(smsUrl, mode: LaunchMode.externalNonBrowserApplication);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error sending SMS: $e')));
//     }
//   }
//
//   String _getAppUserName() {
//     // This should ideally come from user preferences/settings
//     // For now, returning a placeholder
//     return 'My Byaj Book User';
//   }
//
//   // Load updated contact data
//   void _loadContact() {
//     final provider = Provider.of<TransactionProviderr>(context, listen: false);
//     final updatedContact = provider.getContactById(_contact.contactId);
//     if (updatedContact != null) {
//       setState(() {
//         // Replace local reference with fresh one
//         _contact = updatedContact;
//         // _loadTransactions();
//         _filterTransactions();
//       });
//     } else {
//       // Contact might have been deleted
//       Navigator.pop(context);
//     }
//   }
//
//
// }
