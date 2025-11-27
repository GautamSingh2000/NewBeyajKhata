import 'dart:io';

import 'package:byaj_khata_book/core/constants/ContactType.dart';
import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/data/models/Transaction.dart';
import 'package:byaj_khata_book/screens/Home/tabs/IntrestEntries.dart';
import 'package:byaj_khata_book/screens/Home/tabs/StandardEntries.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../../core/constants/InterestPeriod.dart';
import '../../core/constants/InterestType.dart';
import '../../core/constants/RouteNames.dart';
import '../../core/utils/FormatCompactCurrency.dart';
import '../../core/utils/HomeScreenEnum.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../data/models/Contact.dart';
import '../../providers/HomeProvider.dart';
import '../../providers/TransactionProviderr.dart';
import '../../widgets/FilterChip.dart';
import '../../widgets/SortOption.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWithInterest = false;
  double _cachedTotalToGive = 0.0;
  double _cachedTotalToGet = 0.0;

  // Interest calculation variables
  double _interestToPay = 0.0; // Interest to pay
  double _interestToReceive = 0.0; // Interest to receive
  double _principalToPay = 0.0; // Principal to pay
  double _principalToReceive = 0.0; // Principal to receive
  final List<Contact> _withoutInterestContacts = [];
  final List<Contact> _withInterestContacts = [];

  late String _searchQuery;
  late String _interestViewMode; // 'all', 'get', 'pay'
  late FilterMode _filterMode ; // 'All', 'You received', 'You paid'
  late SortMode _sortMode ;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: _homeFAB(),
        backgroundColor: Colors.white,
        body: Column(
            children: [
                _buildTabBar(),
              _buildBalanceSummary(),
              _buildSearchBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              StandardEntries(), // ✅ will show when "Standard Entries" tab is selected
              InterestEntries(), // ✅ will show when "Interest Entries" tab is selected
            ],
          ),
        ),
        ]
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final homeProvider = Provider.of<HomeProvider>(context,listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.grey.shade600, size: 20),
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    // When focused, scroll to top of the page to show more results
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                },
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Find person by name or amount',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      homeProvider.updateSearchQuery(value);
                      // _searchQuery = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  onTap: () {
                    // When tapped, also ensure visibility by scrolling
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.0,
                      );
                    });
                  },
                ),
              ),
            ),
            Container(height: 26, width: 1, color: Colors.grey.shade200),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  _showFilterOptions(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.tune,
                    color: AppColors.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  _showQRCodeOptions(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeOptions(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment QR Code',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppColors.gradientStart,
                              ),
                              onPressed: () async {
                                await _pickQRCodeImage();
                                Navigator.pop(context);
                                _showQRCodeOptions(context);
                              },
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _deleteQRCode();
                                Navigator.pop(context);
                                _showQRCodeOptions(context);
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set your QR code for receiving payments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Check if QR code exists
                    FutureBuilder<String?>(
                      future: provider.getStoredQRCodePath(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        final qrCodePath = snapshot.data;

                        if (qrCodePath != null && qrCodePath.isNotEmpty) {
                          // Show existing QR code
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 200,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show full screen image with zoom capability
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              backgroundColor: Colors.black,
                                              iconTheme: const IconThemeData(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.black,
                                            body: Center(
                                              child: InteractiveViewer(
                                                panEnabled: true,
                                                boundaryMargin:
                                                const EdgeInsets.all(20),
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image.file(
                                                  File(qrCodePath),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(qrCodePath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        } else {
                          // No QR code set yet
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 200,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No QR code set',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _pickQRCodeImage();
                                  Navigator.pop(context);
                                  _showQRCodeOptions(context);
                                },
                                icon: const Icon(
                                  Icons.upload,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Upload QR Code',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gradientStart,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.gradientStart,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickQRCodeImage() async {
    final provider = Provider.of<HomeProvider>(context);

    try {
      final imagePickerHelper = ImagePickerHelper();
      final imageFile = await imagePickerHelper.pickImage(
        context,
        ImageSource.gallery,
      );

      if (imageFile != null) {
        // Save the image path to SharedPreferences
        provider.setQRCodePath(imageFile);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading QR code: $e')));
      }
    }
  }

  void _showFilterOptions(BuildContext context) {

    final homeProvider = Provider.of<HomeProvider>(context,listen: false);
    // Use the current filter and sort modes as defaults
    FilterMode selectedFilter = _filterMode;
    SortMode selectedSort = _sortMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateModal(() {
                          selectedFilter = FilterMode.all;
                          selectedSort = SortMode.recent;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          color: AppColors.gradientStart,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter by',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Different filter options based on current tab
                if (_isWithInterest) ...[
                  // With Interest filter options - Borrower/Lender
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      filterChip(
                        label: FilterMode.all.label,
                        isSelected: selectedFilter == FilterMode.all,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.all,
                        ),
                      ),
                      filterChip(
                        label: FilterMode.youReceived.label,
                        isSelected: selectedFilter == FilterMode.youReceived,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.youReceived,
                        ),
                      ),
                      filterChip(
                        label: FilterMode.youPaid.label,
                        isSelected: selectedFilter == FilterMode.youPaid,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.youPaid,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Without Interest filter options - You received/You paid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      filterChip(
                        label: FilterMode.all.label,
                        isSelected: selectedFilter == FilterMode.all,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.all,
                        ),
                      ),
                      filterChip(
                        label: FilterMode.youReceived.label,
                        isSelected: selectedFilter == FilterMode.youReceived,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.youReceived,
                        ),
                      ),
                      filterChip(
                        label: FilterMode.youPaid.label,
                        isSelected: selectedFilter == FilterMode.youPaid,
                        onSelected: () => setStateModal(
                              () => selectedFilter = FilterMode.youPaid,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                Text(
                  'Sort by',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Simplified sort options
                sortOption(
                  title: SortMode.recent.label,
                  isSelected: selectedSort == SortMode.recent,
                  onTap: () =>
                      setStateModal(() => selectedSort = SortMode.recent),
                ),
                sortOption(
                  title: SortMode.highToLow.label,
                  isSelected: selectedSort == SortMode.highToLow,
                  onTap: () =>
                      setStateModal(() => selectedSort = SortMode.highToLow),
                ),
                sortOption(
                  title: SortMode.lowToHigh.label,
                  isSelected: selectedSort == SortMode.lowToHigh,
                  onTap: () =>
                      setStateModal(() => selectedSort = SortMode.lowToHigh),
                ),
                sortOption(
                  title: SortMode.byName.label,
                  isSelected: selectedSort == SortMode.byName,
                  onTap: () =>
                      setStateModal(() => selectedSort = SortMode.byName),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // Apply the selected filters and sorting by setting state variables
                      setState(() {
                        homeProvider.updateFilterMode(selectedFilter);
                        homeProvider.updateSortMode(selectedSort);
                        // _filterMode = selectedFilter;
                        // _sortMode = selectedSort;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Applied: $selectedFilter, $selectedSort',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        gradient: AppColors.lightBlueGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You Will Pay',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Remove the original FittedBox display and keep only the white button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          formatCompactCurrency(_cachedTotalToGive),
                          style: GoogleFonts.poppins(
                            fontSize: _getButtonFontSize(_cachedTotalToGive),
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      if (_isWithInterest) ...[
                        // Add small text below showing interest details
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'P: ${formatCompactCurrency(_principalToPay)} + I: ${formatCompactCurrency(_interestToPay)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You Will Receive',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Remove the original FittedBox display and keep only the white button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          formatCompactCurrency(_cachedTotalToGet),
                          style: GoogleFonts.poppins(
                            fontSize: _getButtonFontSize(_cachedTotalToGet),
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      if (_isWithInterest) ...[
                        // Add small text below showing interest details
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'P: ${formatCompactCurrency(_principalToReceive)} + I: ${formatCompactCurrency(_interestToReceive)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setTransactionsAndContacts() {
    if (!mounted) return;

// Clear previous lists — critical fix
    _withInterestContacts.clear();
    _withoutInterestContacts.clear();

// Reset totals before processing any contacts
    _principalToPay = 0.0;
    _principalToReceive = 0.0;
    _interestToPay = 0.0;
    _interestToReceive = 0.0;
    _cachedTotalToGive = 0.0;
    _cachedTotalToGet = 0.0;

    // Get transaction provider
    final transactionProvider = Provider.of<TransactionProviderr>(context, listen: false);

    // Get all contacts from the provider
    final allContacts = transactionProvider.contacts;
    if (allContacts.isEmpty) {
      // If there are no contacts in the provider, retry after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _setTransactionsAndContacts();
          });
        }
      });
      return;
    }

    // Reset totals before processing any contacts to prevent accumulation
    // _principalToPay = 0.0;
    // _principalToReceive = 0.0;
    // _interestToPay = 0.0;
    // _interestToReceive = 0.0;
    // _cachedTotalToGive = 0.0;
    // _cachedTotalToGet = 0.0;

    // Process all contacts - for both tabs to ensure data is available
    for (final contact in allContacts) {
      final contactId = contact.contactId;
      if (contactId.isEmpty) continue;

      // Add to appropriate list based on interest setting
      if (contact.interestType == InterestType.withInterest) {
        // With interest contacts
        if (!_withInterestContacts.contains(contact)) {
          _withInterestContacts.add(contact);
        }
      } else {
        // Without interest contacts
        if (!_withoutInterestContacts.contains(contact)) {
          _withoutInterestContacts.add(contact);
        }
      }
    }

    // Sort contacts by lastEditedAt (newest first)
    _withoutInterestContacts.sort((a, b) {
      final aTime = a.lastEditedAt ;
      final bTime = b.lastEditedAt ;
      return bTime.compareTo(aTime);
    });

    _withInterestContacts.sort((a, b) {
      final aTime = a.lastEditedAt ;
      final bTime = b.lastEditedAt ;
      return bTime.compareTo(aTime);
    });

    // For with-interest mode, calculate interest for all contacts
    if (_withInterestContacts.isNotEmpty) {
      _calculateInterestSummary();
    }

    // Update cached totals based on current display mode
    _updateCachedTotals();
  }

  void _calculateInterestSummary() {
    final transactionProvider = Provider.of<TransactionProviderr>(context, listen: false);
    // Reset totals before calculation
    _interestToPay = 0.0;
    _interestToReceive = 0.0;
    _principalToPay = 0.0;
    _principalToReceive = 0.0;
    _cachedTotalToGive = 0.0;
    _cachedTotalToGet = 0.0;

    for (int i = 0; i < _withInterestContacts.length; i++) {
      final contact = _withInterestContacts[i];
      final contactId = contact.contactId;
      if (contactId.isEmpty) continue;

      // Get contact type and transaction info
      final ContactType contactType = contact.contactType;
      final double interestRate = contact.interestRate;
      final bool isMonthly = contact.interestPeriod == InterestPeriod.monthly;

      final transactions = transactionProvider.getTransactionsForContact(contactId);
      double principalAmount = contact.principal;
      // If there are no transactions, skip interest calculation
      if (transactions.isEmpty) {
        // Reset interest values for this contact
        contact.interestDue = 0.0;
        if (contactType == ContactType.borrower) {
          // For borrowers, we get the money
          _principalToReceive += principalAmount;
          _interestToReceive += 0.0;
        } else if (contactType == ContactType.lender) {
          // For lenders, we pay the money
          _principalToPay += principalAmount;
          _interestToPay += 0.0;
        }
        // contact.displayAmount = contact.displayAmount;
        continue;
      }

      // Calculate principal (use amount from contact which is already set)


      // Calculate interest directly using helper method
      double totalInterestDue = _calculateUpdatedInterestDue(contact);

      // Make sure we update the contact in the list
      _withInterestContacts[i] = contact;

      // Add to totals based on relationship type
      if (contactType == ContactType.borrower) {
        // For borrowers, we get the money
        _principalToReceive += principalAmount;
        _interestToReceive += totalInterestDue;
      } else if (contactType == ContactType.lender) {
        // For lenders, we pay the money
        _principalToPay += principalAmount;
        _interestToPay += totalInterestDue;
      }
    }

    // Always update cached totals after calculating interest
    _updateCachedTotals();
  }

  void _updateCachedTotals() {
    final logger = Logger();
    setState(() {
      if (_isWithInterest) {
        _cachedTotalToGive = _principalToPay + _interestToPay;
        _cachedTotalToGet = _principalToReceive + _interestToReceive;
        logger.e(
            "With interest totals - To Give: $_cachedTotalToGive, To Get: $_cachedTotalToGet is withintrest");
      } else {
        // For standard entries, reset and calculate the totals fresh each time
        _cachedTotalToGive = 0.0;
        _cachedTotalToGet = 0.0;

        // Use direct balance calculation for each contact
        final transactionProvider = Provider.of<TransactionProviderr>(
            context, listen: false);

        for (var contact in _withoutInterestContacts) {
          final contactId = contact.contactId;
          if (contactId.isEmpty) continue;

          // Get transaction-based balance directly from provider
          final balance = transactionProvider.calculateBalance(contactId);

          if (balance < 0) {
            _cachedTotalToGive += balance.abs();
          } else if (balance > 0) {
            _cachedTotalToGet += balance;
          }
        }
        logger.e(
            "Without interest totals - To Give: $_cachedTotalToGive, To Get: $_cachedTotalToGet is withoutintrest");
      }
    });
  }

  double _calculateUpdatedInterestDue(Contact contact) {
    if (contact.interestType != InterestType.withInterest) return 0.0;
    if (contact.principal <= 0) return 0.0;

    final double principal = contact.principal;
    final double rate = contact.interestRate;
    final InterestPeriod period = contact.interestPeriod ?? InterestPeriod.yearly;
    final DateTime now = DateTime.now();
    final DateTime lastCycleDate = contact.lastInterestCycleDate ?? now;
    final int daysPassed = now.difference(lastCycleDate).inDays;

    // ✅ Skip if same day (no new growth)
    if (daysPassed <= 0) return contact.interestDue;

    double newInterest = 0.0;
    switch (period) {
      case InterestPeriod.daily:
        newInterest = principal * (rate / 100) * daysPassed;
        break;
      case InterestPeriod.weekly:
        final weeks = daysPassed / 7.0;
        newInterest = principal * (rate / 100) * weeks;
        break;
      case InterestPeriod.monthly:
        final months = daysPassed / 30.0;
        newInterest = principal * (rate / 100) * months;
        break;
      case InterestPeriod.yearly:
        final years = daysPassed / 365.0;
        newInterest = principal * (rate / 100) * years;
        break;
    }

    // ✅ Add new interest to existing unpaid interest
    double totalInterest = contact.interestDue + newInterest;

    return totalInterest;
  }

  double _getButtonFontSize(double amount) {
    if (amount >= 10000000) {
      // ≥ 1 crore (always abbreviated)
      return 16.0;
    } else if (amount >= 1000000) {
      // ≥ 10 lakh
      return 14.0;
    } else if (amount >= 100000) {
      // ≥ 1 lakh
      return 15.0;
    } else {
      return 16.0; // Default size for smaller amounts
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final transactionProvider = Provider.of<TransactionProviderr>(context, listen: false);
    transactionProvider.addListener(() {
      if (!mounted) return;
      setState(() {
        // Only recalculate totals without rebuilding full UI
        _setTransactionsAndContacts();
        _updateCachedTotals();
      });
    });

    final homeProvider = Provider.of<HomeProvider>(context,listen: false);

    _searchQuery = homeProvider.searchQuery;
    _interestViewMode = homeProvider.interestViewMode;
    _filterMode = homeProvider.filterMode;
    _sortMode = homeProvider.sortMode;

    homeProvider.addListener((){
      setState(() {
        _searchQuery = homeProvider.searchQuery;
        _interestViewMode = homeProvider.interestViewMode;
        _filterMode = homeProvider.filterMode;
        _sortMode = homeProvider.sortMode;
      });
    });

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != (_isWithInterest ? 1 : 0)) {
        setState(() {
          _isWithInterest = _tabController.index == 1;
          homeProvider.updateIsWithInterest(_isWithInterest);
          // Clear existing data for the target tab
          if (_isWithInterest) {
            _withInterestContacts.clear();
          } else {
            _withoutInterestContacts.clear();
          }
          // Force data reload immediately after tab change
          _setTransactionsAndContacts();
          // Update cached totals after data is loaded
          _updateCachedTotals();
        });
      }
    });
  }

  Future<void> _deleteQRCode() async {
    final provider = Provider.of<HomeProvider>(context);

    try {
      bool result = await provider.deleteQRCode();
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code deleted successfully')),
        );
      }
    } catch (e) {
      // Removed debug print
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting QR code: $e')));
    }
  }

  Widget _buildTabBar() {
    final provider = Provider.of<HomeProvider>(context,listen: true);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.gradientStart,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              onTap: (index) {
                // Force a refresh when tab is tapped (not just when animation completes)
                setState(() {
                  _isWithInterest = index == 1;
                  provider.updateIsWithInterest(_isWithInterest);
                  // Clear existing data for the target tab to guarantee fresh data
                  if (_isWithInterest) {
                    _withInterestContacts.clear();
                  } else {
                    _withoutInterestContacts.clear();
                  }

                  // Force immediate data reload
                  // _syncContactsWithTransactions();
                });
              },
              indicatorColor: Colors.transparent,
              indicatorWeight: 0,
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Standard Entries', height: 36),
                Tab(text: 'Interest Entries', height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeFAB(){
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: AppColors.lightBlueGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showAddContactOptions(context);
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Person',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddContactOptions(BuildContext context) {
    // Find HomeContent state to get the current tab (with interest or without interest)
    final bool isWithInterest = _isWithInterest ;
    context.push(
      RouteNames.selectContact,
      extra: isWithInterest, // pass your data to the screen
    );
  }


}
