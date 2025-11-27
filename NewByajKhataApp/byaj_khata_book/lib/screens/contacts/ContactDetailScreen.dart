import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:byaj_khata_book/core/constants/ContactType.dart';
import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
import 'package:byaj_khata_book/data/models/Transaction.dart';
import 'package:byaj_khata_book/providers/ReminderProvider.dart';
import 'package:byaj_khata_book/screens/contacts/utils/ActionButtons.dart';
import 'package:byaj_khata_book/screens/contacts/utils/SingleInterestDetailsColum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/InterestPeriod.dart';
import '../../core/constants/RouteNames.dart';
import '../../core/theme/AppColors.dart';
import '../../core/utils/StringUtils.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/utils/permission_handler.dart';
import '../../data/models/Contact.dart' as my_models;
import '../../data/models/Contact.dart';
import '../../data/models/Reminder.dart';
import '../../providers/TransactionProviderr.dart';
import '../../services/pdf_template_service.dart';
import '../../widgets/ConfirmDialog.dart';

class ContactDetailScreen extends StatefulWidget {
  final String contactId;
  final bool showSetupPrompt;
  final bool isWithInterest;
  final bool showTransactionDialogOnLoad;
  final String? dailyInterestNote; // Add this parameter but we won't use it

  const ContactDetailScreen({
    Key? key,
    required this.contactId,
    this.showSetupPrompt = false,
    this.isWithInterest = false,
    this.showTransactionDialogOnLoad = false,
    this.dailyInterestNote,
  }) : super(key: key);

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen>
    with RouteAware {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;
  late my_models.Contact _contact;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');


  bool isImageUploading = false;

  List<Transaction> _filteredTransactions = [];
  bool _isSearching = false;

  late TransactionProviderr _transactionProvider;
  late ReminderProvider _reminderProvider;
  late Logger logger;

  String _contactId = '';
  String _selectedFilter = 'All';
  double innerInterestDue = 0.0;
  List<String> globalSelectedImages = [];


  Future<void> _downloadImagesToGallery(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images to download')),
        );
      }
      return;
    }

    // Ask for permissions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required')),
          );
        }
        return;
      }
    }

    const channel = MethodChannel("com.example.save_to_gallery");
    int successCount = 0;

    for (final path in imagePaths) {
      try {
        final original = File(path);

        if (!original.existsSync()) continue;

        // Create custom folder
        final Directory targetDir =
        Directory("/storage/emulated/0/Download/ByajKhataReceipts");

        if (!targetDir.existsSync()) {
          targetDir.createSync(recursive: true);
        }

        // Create new file name
        final newPath =
            "${targetDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

        // Copy file to public folder
        final newFile = await original.copy(newPath);

        // Update gallery
        await channel.invokeMethod("scanFile", newFile.path);

        successCount++;
      } catch (e) {
        print("SAVE ERROR: $e");
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Downloaded $successCount / ${imagePaths.length} images")),
      );
    }
  }




  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_filterTransactions);
    // Initialize contact ID
    _contactId = widget.contactId;
    final provider = Provider.of<TransactionProviderr>(context, listen: false);
    final loadedContact = provider.getContactById(widget.contactId);
    _contact = loadedContact!;
    // Show setup prompt for new contacts after a short delay
    if (widget.showSetupPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetupPrompt();
      });
    }

    // Show transaction dialog if requested
    if (widget.showTransactionDialogOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddTransactionDialog();
      });
    }
  }

  void _onBackPressed() {
    ScaffoldMessenger.of(
      context,
    ).clearSnackBars(); // ✅ Safe because widget is still active
    Navigator.pop(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionProvider = Provider.of<TransactionProviderr>(context);
    _reminderProvider = Provider.of<ReminderProvider>(context);
    logger = new Logger();
    _filterTransactions();
  }

  @override
  void didPopNext() {
    // This is called when returning to this screen
    // Refresh data
    setState(() {
      _refreshData();
    });
    super.didPopNext();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtTop = position.pixels <= 50;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50;

    setState(() {
      _showScrollToTop = !isAtTop;
      _showScrollToBottom = !isAtBottom;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget transactionFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAnimatedFilterButton('All'),
          const SizedBox(width: 10),
          _buildAnimatedFilterButton('Received'),
          const SizedBox(width: 10),
          _buildAnimatedFilterButton('Paid'),
        ],
      ),
    );
  }

  Widget _buildAnimatedFilterButton(String label) {
    final bool isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        if (_selectedFilter != label) {
          setState(() {
            _selectedFilter = label;
          });
          // small delay to show animation before applying filter
          Future.delayed(
            const Duration(milliseconds: 100),
            _filterTransactions,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.08 : 1.0),
        // small scale-up animation
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gradientStart
              : Colors.grey.shade200.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.blue0001.withOpacity(0.4)
                  : Colors.transparent,   // ⭐ no more [] empty list
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: isSelected ? 10 : 9,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final transactions = _transactionProvider.getTransactionsForContact(
        _contactId,
      );

      // First filter the transactions
      // 🔹 Step 1: Search Filter
      List<Transaction> results = transactions.where((tx) {
        final matchesQuery =
            query.isEmpty ||
                tx.note.toLowerCase().contains(query) ||
                tx.amount.toString().contains(query);
        return matchesQuery;
      }).toList();

      // 🔹 Step 2: Type Filter
      if (_selectedFilter == 'Received') {
        results = results.where((tx) => tx.transactionType == 'got').toList();
      } else if (_selectedFilter == 'Paid') {
        results = results.where((tx) => tx.transactionType == 'gave').toList();
      }

      // 🔹 Step 3: Sort by date
      results.sort((a, b) => b.date.compareTo(a.date));

      _filteredTransactions = results;
    });
  }

  // Calculate total balance
  double _calculateBalance() {
    return _transactionProvider.calculateBalance(_contactId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        // Custom leading widget
        leading: IconButton(
          icon: SvgPicture.asset(
            "assets/icons/left_icon.svg",
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () {
            _onBackPressed(); // or your own logic
          },
        ),
        title: Text(
          _contact.name,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showContactOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // 🔹 Summary card
                  if (_contact.interestType == InterestType.withInterest)
                    _buildInterestSummaryCard(_contact)
                  else
                    _buildBasicSummaryCard(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Left side — Filter buttons
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: transactionFilterRow(),
                        ),
                      ),

                      // 🔹 Right side — Search icon + expanding search bar
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    if (!_isSearching)
                                      _searchController.clear();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  height: 36,
                                  width: 36,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          RotationTransition(
                                            turns: Tween(
                                              begin: 0.75,
                                              end: 1.0,
                                            ).animate(animation),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: Icon(
                                        _isSearching
                                            ? Icons.close_rounded
                                            : Icons.search_rounded,
                                        key: ValueKey(
                                          _isSearching ? 'close' : 'search',
                                        ),
                                        size: 24,
                                        color: AppColors.blue0001,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 🔹 Animated Search Bar (appears below icon)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) =>
                        SizeTransition(sizeFactor: animation, child: child),
                    child: _isSearching
                        ? Padding(
                      key: const ValueKey('searchField'),
                      padding: const EdgeInsets.only(
                        right: 16,
                        bottom: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search amount  or note',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  // 🔹 Transaction Header Row
                  transactionHeaderRow(context),
                  _filteredTransactions.isEmpty
                      ? const Center(child: Text('No transactions found'))
                      : ListView.builder(
                    shrinkWrap: true,
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 150),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      return _buildTransactionItem(tx);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Scroll to Top Button
          if (_showScrollToTop)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'scrollToTopBtn',
                mini: true,
                backgroundColor: AppColors.blue0001.withAlpha(80),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),

          // 🔹 Scroll to Bottom Button
          if (_showScrollToBottom)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'scrollToBottomBtn',
                mini: true,
                backgroundColor: AppColors.blue0001.withAlpha(80),
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // 👈 rounded corners
                    ),
                  ),
                  onPressed: () => _addTransaction('gave'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_drop_up, size: 25, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'I GAVE',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // 👈 rounded corners
                    ),
                  ),
                  onPressed: () => _addTransaction('got'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_drop_down,
                        size: 25,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'I Receive',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImagesDialog(List<String> images, int startIndex) {
    if (images.isEmpty) return;

    final PageController pageController = PageController(initialPage: startIndex);
    final ScrollController dotsScrollController = ScrollController();
    int currentPage = startIndex;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void _onPageChanged(int index) {
              setState(() {
                currentPage = index;
              });

              // center the active dot in the dot list
              // dot item width estimation
              final double dotItemWidth = 24.0; // active width approx
              final double spacing = 8.0;
              final double totalItem = dotItemWidth + spacing;
              final screenWidth = MediaQuery.of(context).size.width;
              final targetOffset = (index * totalItem) - (screenWidth / 2) + (dotItemWidth / 2);

              // clamp offset
              final maxScroll = (images.length * totalItem) - screenWidth;
              final clamped = targetOffset.clamp(0.0, maxScroll < 0 ? 0.0 : maxScroll);

              dotsScrollController.animateTo(
                clamped,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Top bar with close + download
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          // Download all button
                          IconButton(
                            tooltip: 'Download all images',
                            icon: SvgPicture.asset(
                              'assets/icons/download.svg',
                              width: 22,
                              height: 22,
                              // colorFilter: ColorFilter.mode(AppColors.blue0001, BlendMode.srcIn),
                            ),
                            onPressed: () {
                              // call helper to download all images
                              _downloadImagesToGallery(images);
                            },
                          ),
                        ],
                      ),
                    ),

                    // PageView (images)
                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: images.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final path = images[index];
                          return InteractiveViewer(
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.black12,
                              child: Image.file(File(path), fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Scrollable Dots Indicator (center-focused, active dot bigger)
                    SizedBox(
                      height: 28,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(images.length, (index) {
                            bool isActive = index == currentPage;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: isActive ? 12 : 8,
                              width: isActive ? 12 : 8,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blueAccent : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }




  Widget _buildTransactionItem(Transaction tx) {
    final isGave = tx.transactionType == 'gave';
    final hasImage = tx.imagePath != null && tx.imagePath!.isNotEmpty;
    final date = DateFormat("dd MMM yy").format(tx.date);
    final time = DateFormat("hh:mm a").format(tx.date);

    final allTransactions = _transactionProvider.getTransactionsForContact(
      _contactId,
    );
    final originalIndex = allTransactions.indexOf(tx);

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400; // responsive scaling

    return GestureDetector(
      onTap: () => _editTransaction(tx, originalIndex),
      onLongPress: () => _confirmDeleteTransaction(tx, originalIndex),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 1,
        color: Colors.white,
        shadowColor: Colors.white12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(
              // bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TOP ROW (weighted) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Date + Time + Type (2 weight)
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          isGave
                              ? "assets/icons/arrow_up.svg"
                              : "assets/icons/arrow_down.svg",
                          width: 14 * scale,
                          height: 14 * scale,
                          colorFilter: ColorFilter.mode(
                            isGave ? Colors.red : Colors.green,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: GoogleFonts.poppins(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildVerticalDivider(),
                  // RIGHT: Debit (1) | Credit (1)
                  // Debit
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: isGave
                          ? Text(
                        tx.amount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      )
                          : const SizedBox(),
                    ),
                  ),

                  _buildVerticalDivider(),
                  // Credit
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: !isGave
                          ? Text(
                        tx.amount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      )
                          : const SizedBox(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding:  EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 1),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 9 * scale,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                        children: [
                          Text(
                            isGave ? "Payment sent" : "Payment received",
                            style: GoogleFonts.poppins(
                              fontSize: 9 * scale,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          tx.isInterestPayment ? Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                                color: AppColors.yellow,
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8),
                              child: Text(
                                "Interest",
                                style: GoogleFonts.poppins(
                                  fontSize: 9 * scale,
                                  color: AppColors.yellow0001,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                          ) : SizedBox()
                        ]
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 18 * scale),
                        child: Row(
                          children: [
                            Text(
                              "Balance: ",
                              style: GoogleFonts.poppins(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              tx.balanceAfterTx.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: tx.balanceAfterTx >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ===== NOTE + RECEIPT =====
                      if (tx.note.isNotEmpty || hasImage) ...[
                        const SizedBox(height: 4),
                        if (tx.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Text(
                              tx.note.length > 10
                                  ? '${tx.note.substring(0, 10)}...'
                                  : tx.note,
                              style: GoogleFonts.poppins(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        if (hasImage)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => {
                                    if (tx.imagePath != null && tx.imagePath!.isNotEmpty) {
                                      _showFullImagesDialog(tx.imagePath!, 0)
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/receit_icon.svg",
                                          width: 12,
                                          height: 12,
                                          colorFilter: ColorFilter.mode(
                                            AppColors.blue0001,
                                            BlendMode.srcIn,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'View Receipt',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.blue0001,
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                // Download icon to the right
                                GestureDetector(
                                  onTap: () {
                                    if (tx.imagePath != null && tx.imagePath!.isNotEmpty) {
                                      _downloadImagesToGallery(tx.imagePath!);
                                    } else {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No receipt to download')),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: SvgPicture.asset(
                                      'assets/icons/download_icon.svg',
                                      width: 18,
                                      height: 12,
                                      colorFilter: ColorFilter.mode(AppColors.blue0001, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )

                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 18,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  // void _showFullImage(BuildContext context, String imagePath) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           AppBar(
  //             backgroundColor: Colors.transparent,
  //             elevation: 0,
  //             title: Text('Receipt'),
  //             leading: IconButton(
  //               icon: const Icon(Icons.close),
  //               onPressed: () => Navigator.pop(context),
  //             ),
  //           ),
  //           Container(
  //             constraints: BoxConstraints(
  //               maxHeight: MediaQuery.of(context).size.height * 0.6,
  //             ),
  //             child: Image.file(File(imagePath), fit: BoxFit.contain),
  //           ),
  //           const SizedBox(height: 16),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // void _showFullImagesDialog(List<String> images, int startIndex) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       PageController controller = PageController(initialPage: startIndex);
  //
  //       return Dialog(
  //         insetPadding: EdgeInsets.all(10),
  //         child: Column(
  //           children: [
  //             // Close button
  //             Align(
  //               alignment: Alignment.topRight,
  //               child: IconButton(
  //                 icon: Icon(Icons.close),
  //                 onPressed: () => Navigator.pop(context),
  //               ),
  //             ),
  //
  //             Expanded(
  //               child: PageView.builder(
  //                 controller: controller,
  //                 itemCount: images.length,
  //                 itemBuilder: (context, index) {
  //                   return InteractiveViewer(
  //                     child: Image.file(
  //                       File(images[index]),
  //                       fit: BoxFit.contain,
  //                     ),
  //                   );
  //                 },
  //               ),
  //             )
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }


  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // keeps it tight to content
          children: [
            Text(
              _contact.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Phone', _contact.displayPhone ?? _contact.name),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Category',
              StringUtils.capitalizeFirstLetter(_contact.category),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Account Type',
              _contact.interestType == InterestType.withoutInterest
                  ? 'No Interest'
                  : "With Interest",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(value),
      ],
    );
  }

  void _showContactOptions() async {
    final result = await context.push<Contact>(
      RouteNames.editContact,
      extra: {
        'contact': _contact,
        'isWithInterest': _contact.interestType == InterestType.withInterest}, // pass the contact as extra
    );

    if (result == true) {
      // Refresh the screen if contact was updated or deleted
      setState(() {
        _loadContact();
      });
    }
  }

  void _confirmDeleteContact() {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Contact',
        // content: 'Are you sure you want to delete ${_contact['name']}? This will delete all transaction history.',
        content:
        'Are you sure you want to delete ${_contact.name}? This will delete all transaction history.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () async {
          // Delete contact using TransactionProvider
          final provider = Provider.of<TransactionProviderr>(
            context,
            listen: false,
          );
          // final success = await provider.deleteContact(_contact['phone']);
          final success = await provider.deleteContact(_contact.contactId);

          // Close dialog
          Navigator.pop(context);

          if (success) {
            // Return to contacts list with deleted status
            Navigator.pop(context, true);

            // Show confirmation snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_contact.name} deleted',
                  style: GoogleFonts.poppins(),
                ),
              ),
              // SnackBar(content: Text('${_contact['name']} deleted',  style: GoogleFonts.poppins())),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to delete contact',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _addTransaction(String type) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    // String? imagePath;
    List<String> selectedImages = [];
    String? amountError; // Add this to track error state
    // Define maximum amount (99 crore)
    const double maxAmount = 990000000.0;
    // double currentBalance = _contact.principal;
    double principal = _contact.principal;

    // Check if this is a with-interest contact
    final ContactType relationshipType = _contact.contactType;

    // Default to principal amount
    bool isPrincipalAmount = true;

    // Determine if we should show the interest option based on relationship and transaction type
    final bool showInterestOption = widget.isWithInterest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom sheet drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: type == 'gave'
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        radius: 14,
                        child: SvgPicture.asset(
                          type == 'gave'
                              ? "assets/icons/arrow_up.svg"
                              : "assets/icons/arrow_down.svg",
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            type == 'gave' ? Colors.red : Colors.green,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type == 'gave' ? 'Paid' : 'Received',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  Text(
                    'Amount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            filled: true,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                // color when focused
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                // color when not focused
                                width: 1,
                              ),
                            ),
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixText: '₹ ',
                            errorText: amountError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date selection now appears directly to the right of amount
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: type == 'gave'
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/calendar.svg",
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(
                                  type == 'gave' ? Colors.red : Colors.green,
                                  BlendMode.srcIn,
                                ),
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(selectedDate).split(',')[0],
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Note Field
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note (optional)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 80, // ✅ Match receipt box height
                              child: TextField(
                                controller: noteController,
                                maxLines: null,
                                expands: true,
                                // ✅ Makes text fill height evenly
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: 'Add a note...',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 🔹 Receipt Upload
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt (optional)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                _showImageSourceOptions(
                                  context,
                                      (paths) {
                                    setState(() {
                                      selectedImages = paths;
                                      globalSelectedImages = paths;
                                      isImageUploading = false;
                                    });
                                  },
                                  setState,  // ⭐ THIS IS THE BOTTOM SHEET setState
                                );
                              },
                              child: Container(
                                height: 80, // ✅ Same as Note height
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade400, width: 1),
                                ),
                                child: isImageUploading
                              ? Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.blue),
                                  SizedBox(height: 6),
                                  Text(
                                    "Loading images...",
                                    style: GoogleFonts.poppins(fontSize: 10),
                                  )
                                ],
                              ),
                            )
                            : selectedImages.isEmpty
                                    ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        size: 24,
                                        color: type == 'gave'
                                            ? Colors.red.withOpacity(0.7)
                                            : Colors.green.withOpacity(0.7)),
                                    const SizedBox(height: 4),
                                    Text('Add receipt',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: type == 'gave'
                                              ? Colors.red.withOpacity(0.7)
                                              : Colors.green.withOpacity(0.7),
                                        )),
                                  ],
                                )
                                    : GestureDetector(
                                  onTap: () {
                                    _showFullImagesDialog(selectedImages, 0);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(selectedImages.first),   // 👈 Show only first preview
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Principal/Interest Switch (Only for with-interest contacts when appropriate)
                  if (showInterestOption) ...[
                    const SizedBox(height: 12),
                    if ((relationshipType == ContactType.borrower &&
                        type == 'got') ||
                        (relationshipType == ContactType.lender &&
                            type == 'gave')) ...[
                      Text(
                        'Is this amount for:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSelectionButton(
                            title: 'Interest',
                            isSelected: !isPrincipalAmount,
                            icon: "assets/icons/selected_sip.svg",
                            color: Colors.amber.shade700,
                            onTap: () {
                              setState(() {
                                isPrincipalAmount = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildSelectionButton(
                            title: 'Principal',
                            isSelected: isPrincipalAmount,
                            icon: "assets/icons/money_icon.svg",
                            color: Colors.blue,
                            onTap: () {
                              setState(() {
                                isPrincipalAmount = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    // actualIsPrincipal = true;
                  ],
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              setState(() {
                                amountError = 'Amount is required';
                              });
                              return;
                            }
                            final amount = double.tryParse(
                              amountController.text,
                            );
                            if (amount == null || amount <= 0) {
                              setState(() {
                                amountError = 'Please enter a valid amount';
                              });
                              return;
                            }

                            // Validate maximum amount
                            if (amount > maxAmount) {
                              setState(() {
                                amountError =
                                'Maximum allowed amount is ₹99 cr';
                              });
                              return;
                            }

                            // Create transaction note
                            String note = noteController.text.isNotEmpty
                                ? noteController.text
                                : (type == 'gave'
                                ? 'Payment sent'
                                : 'Payment received');

                            // Add prefix for interest/principal if applicable
                            if (showInterestOption) {
                              String prefix = isPrincipalAmount
                                  ? 'Principal: '
                                  : 'Interest: ';
                              note = prefix + note;
                            }

                            if (!isPrincipalAmount) {

                              double updatedInterestDue = (innerInterestDue - amount).clamp(0, double.infinity);

                              // ✅ Save updated values
                              _contact.interestDue = updatedInterestDue;
                              innerInterestDue = updatedInterestDue;

                              // ✅ Move lastInterestCycleDate to today → new cycle starts tomorrow
                              // _contact.lastInterestCycleDate = DateTime.now();
                              _contact.lastInterestCycleDate = selectedDate;

                              // ✅ Persist updated contact immediately
                              _transactionProvider.updateContact(_contact);

                            } else {
                              _contact.interestDue = innerInterestDue;
                              // Update balance after this transaction
                              if (_contact.contactType ==
                                  ContactType.borrower) {
                                // Borrower owes you
                                if (type == 'gave') {
                                  principal += amount; // You lent more
                                } else if (type == 'got') {
                                  principal -= amount; // They repaid
                                }
                              } else {
                                // Lender - You owe them
                                if (type == 'gave') {
                                  principal -= amount; // You repaid
                                } else if (type == 'got') {
                                  principal += amount; // You borrowed
                                }
                              }

                              // ✅ Corrected logic for isGet
                              if (principal < 0 &&
                                  _contact.contactType == ContactType.lender) {
                                _contact.contactType = ContactType.borrower;
                                principal = principal.abs();
                                logger.e("currentBalance $principal");
                                _contact.isGet = true;
                              } else if (principal < 0 &&
                                  _contact.contactType ==
                                      ContactType.borrower) {
                                _contact.contactType = ContactType.lender;
                                principal = principal.abs();
                                logger.e("currentBalance $principal");
                                _contact.isGet = false;
                              }

                              // ✅ Initialize or update lastInterestCycleDate
                              if (_contact.lastInterestCycleDate == null) {

                                // ✅ Calculate backdated interest ONCE when creating the loan in the past
                                final now = DateTime.now();
                                final days = now.difference(selectedDate).inDays;
                                final interestRate = _contact.interestRate;
                                final period = _contact.interestPeriod ?? InterestPeriod.yearly;

                                double initialInterest = 0.0;
                                switch (period) {
                                  case InterestPeriod.daily:
                                    initialInterest = principal * (interestRate / 100) * days;
                                    break;
                                  case InterestPeriod.weekly:
                                    initialInterest = principal * (interestRate / 100) * (days / 7.0);
                                    break;
                                  case InterestPeriod.monthly:
                                    initialInterest = principal * (interestRate / 100) * (days / 30.0);
                                    break;
                                  case InterestPeriod.yearly:
                                    initialInterest = principal * (interestRate / 100) * (days / 365.0);
                                    break;
                                }

                                _contact.interestDue = initialInterest;   // ✅ Save ₹222 once
                                _contact.lastInterestCycleDate = now;
                              } else {
                                final period = _contact.interestPeriod ?? InterestPeriod.yearly;
                                final nextCycleDate = _getNextCycleDate(_contact.lastInterestCycleDate!, period);
                                if (selectedDate.isAfter(nextCycleDate)) {
                                  _contact.lastInterestCycleDate = nextCycleDate;
                                }
                              }
                            }


                            // Add transaction details
                            _transactionProvider.addTransactionDetails(
                              _contactId,
                              amount,
                              type,
                              selectedDate,
                              note,
                              // imagePath,
                              selectedImages,
                              isPrincipalAmount,
                              balanceAfterTx: principal,
                            );
                            _contact.principal = principal;
                            _contact.displayAmount = principal+innerInterestDue;

                            // Save updated contact
                            _transactionProvider.updateContact(_contact);

                            // Refresh transactions
                            setState(() {
                              _filterTransactions();
                            });

                            Navigator.pop(context);

                            // Show success message
                            final String amountType = isPrincipalAmount
                                ? 'principal'
                                : 'interest';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${type == 'gave' ? 'payment' : 'receipt'} of ${currencyFormat.format(amount)} for $amountType',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave'
                                ? Colors.red
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showImageSourceOptions(
      BuildContext context,
      Function(List<String>) onImagesSelected,
      Function(Function()) bottomSheetSetState,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Image Source'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context,
                  Icons.camera_alt,
                  'Camera',
                      () => _getImage(ImageSource.camera, onImagesSelected, bottomSheetSetState),
                ),
                _buildImageSourceOption(
                  context,
                  Icons.photo_library,
                  'Gallery',
                      () => _getImage(ImageSource.gallery, onImagesSelected, bottomSheetSetState),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildImageSourceOption(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getImage(
      ImageSource source,
      Function(List<String>) onImagesSelected,
      Function(Function()) bottomSheetSetState,
      ) async {
    final picker = ImagePicker();

    bottomSheetSetState(() => isImageUploading = true);  // ⭐ Start loading

    try {
      if (source == ImageSource.gallery) {
        final List<XFile>? pickedFiles = await picker.pickMultiImage(
          imageQuality: 85,
        );

        if (pickedFiles != null && pickedFiles.isNotEmpty) {
          final paths = pickedFiles.map((e) => e.path).toList();

          bottomSheetSetState(() => isImageUploading = false);  // ⭐ Stop loading
          onImagesSelected(paths);
          return paths;
        }
      } else {
        final XFile? imageFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );

        if (imageFile != null) {
          final list = [imageFile.path];

          bottomSheetSetState(() => isImageUploading = false);  // ⭐ Stop loading
          onImagesSelected(list);
          return list;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
    bottomSheetSetState(() => isImageUploading = false);  // ⭐ Stop loading (fallback)
    return [];
  }




  DateTime _getNextCycleDate(DateTime fromDate, InterestPeriod period) {
    switch (period) {
      case InterestPeriod.daily:
        return fromDate.add(Duration(days: 1));
      case InterestPeriod.weekly:
        return fromDate.add(Duration(days: 7));
      case InterestPeriod.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case InterestPeriod.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
    }
  }

  Widget _buildInterestSummaryCard(Contact contact) {
    final transactions = _transactionProvider.getTransactionsForContact(
      _contactId,
    );

    // Base values from Contact model
    double principal = contact.principal;
    double accumulatedInterest = 0.0;
    DateTime? lastInterestCalculationDate;

    // Sort transactions chronologically
    transactions.sort((a, b) => a.date.compareTo(b.date));

    final relationshipType = contact.contactType;
    final isBorrower = relationshipType == ContactType.borrower;

    if (transactions.isNotEmpty) {
       lastInterestCalculationDate = contact.lastInterestCycleDate;
    }
    // --- INTEREST UNTIL TODAY ---
    double interestDue = accumulatedInterest;
    innerInterestDue = interestDue;

    if (
    lastInterestCalculationDate != null &&
        principal > 0 &&
        DateTime.now().difference(lastInterestCalculationDate).inDays > 0) {

      logger.e("inside if ");

      final period = contact.interestPeriod ?? InterestPeriod.yearly;
      final interestRate = contact.interestRate;
      final DateTime lastCycleDate = contact.lastInterestCycleDate ?? lastInterestCalculationDate;
      final DateTime now = DateTime.now();

      // ✅ days passed since last payment or last interest calculation
      final int daysPassed = now.difference(lastCycleDate).inDays;

      double newInterest = 0.0;

      switch (period) {
        case InterestPeriod.daily:
          newInterest = principal * (interestRate / 100) * daysPassed;
          break;

        case InterestPeriod.weekly:
          final weeks = daysPassed / 7.0;
          newInterest = principal * (interestRate / 100) * weeks;
          break;

        case InterestPeriod.monthly:
          final months = daysPassed / 30.0;
          newInterest = principal * (interestRate / 100) * months;
          break;

        case InterestPeriod.yearly:
          final years = daysPassed / 365.0;
          newInterest = principal * (interestRate / 100) * years;
          break;
      }

      final savedUnpaidInterest =  contact.interestDue ;

      // Only add new interest if days have passed (prevents duplicate addition)
      double totalInterest = savedUnpaidInterest;
      if (daysPassed > 0) {
        totalInterest += newInterest;
      }

      interestDue = totalInterest;
      innerInterestDue = totalInterest;
      logger.e("interest is $innerInterestDue");
    }else{
      interestDue = contact.interestDue;
      innerInterestDue = interestDue;
      logger.e("in else part the interest is $innerInterestDue");
    }

    // --- TOTAL DUE ---
    final totalAmount = principal + interestDue;

    final Color relationshipColor = relationshipType == ContactType.borrower
        ? const Color(0xFF5D69E3)
        : const Color(0xFF2E9E7A);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            relationshipColor.withOpacity(0.9),
            relationshipColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: relationshipColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 12,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          relationshipType == ContactType.borrower
                              ? "assets/icons/wallet_filled.svg"
                              : "assets/icons/balance_icon.svg",
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Interest Summary',
                          style: GoogleFonts.poppins(
                            fontSize: context.screenHeight * 0.018,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          StringUtils.capitalizeFirstLetter(
                            relationshipType.name,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 8.0),
                      child: Text(
                        '${_contact.interestRate} % ${_contact.interestPeriod == InterestPeriod.monthly ? 'P.M.' : 'P.A.'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showContactInfo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: singleInterestDetailsColum(
                        title: 'Principal',
                        amount: principal.toString(),
                        icon: "assets/icons/rupee_icon.svg",
                        alignStart: true, // 👈 added
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      height: 50,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      flex: 1,
                      child: singleInterestDetailsColum(
                        title: 'Interest Due',
                        amount: interestDue.toString(),
                        icon: "assets/icons/interest_icon.svg",
                        alignStart: true, // 👈 added
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: singleInterestDetailsColum(
                    title: 'Total :',
                    // icon: "assets/icons/total_amount_icon.svg",
                    amount: totalAmount.toString(),
                    showBgShape: false,
                    titleSize: 14,
                    amountSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- Action Buttons ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  actionButtonCompact(
                    context,
                    Icons.call,
                    'Call',
                    Colors.blue,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _handleCallButton,
                  ),
                  actionButtonCompact(
                    context,
                    Icons.picture_as_pdf,
                    'PDF Report',
                    Colors.red,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE57373), Color(0xFFC62828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _handlePdfReport,
                  ),
                  actionButtonCompact(
                    context,
                    Icons.notifications,
                    'Reminder',
                    Colors.orange,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _setReminder,
                  ),
                  actionButtonCompact(
                    context,
                    Icons.sms,
                    'SMS',
                    Colors.green,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _handleSmsButton,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format large currency values in a compact way
  String _formatCompactCurrency(double amount) {
    if (amount >= 10000000) {
      // 1 crore or more
      return 'Rs. ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else {
      // For values less than 1 crore, show the full number with commas
      return currencyFormat.format(amount);
    }
  }

  // Helper method to format currency text with overflow protection
  Widget _formatCurrencyText(
      double amount, {
        double fontSize = 14,
        FontWeight fontWeight = FontWeight.bold,
        Color? color,
      }) {
    // Format large numbers in a compact way
    String formattedAmount = amount >= 100000
        ? _formatCompactCurrency(amount)
        : currencyFormat.format(amount);

    // Use FittedBox to ensure text fits in its container
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        formattedAmount,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? Colors.black,
        ),
        maxLines: 1,
      ),
    );
  }

  // Basic summary card for contacts without interest
  Widget _buildBasicSummaryCard() {
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    // Choose colors based on balance status
    final Color primaryColor = isPositive
        ? Colors.green.shade700
        : Colors.red.shade700;
    final Color secondaryColor = isPositive
        ? Colors.green.shade400
        : Colors.red.shade400;
    final Color lightColor = isPositive
        ? Colors.green.shade50
        : Colors.red.shade50;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
      ),
      child: Column(
        children: [
          // Main balance section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with label and info button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.account_balance_wallet
                              : Icons.payments,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPositive ? 'You Will RECEIVE' : 'You Will PAY',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showContactInfo,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Balance amount with currency
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. ',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        NumberFormat('#,##,##0.00').format(balance.abs()),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Last updated info
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Last updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                actionButtonCompact(
                  context,
                  Icons.call,
                  'Call',
                  Colors.blue,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
                  ),
                  onTap: _handleCallButton,
                ),
                actionButtonCompact(
                  context,
                  Icons.picture_as_pdf,
                  'PDF Report',
                  Colors.red,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE57373), Color(0xFFC62828)],
                  ),
                  onTap: _handlePdfReport,
                ),
                actionButtonCompact(
                  context,
                  Icons.notifications,
                  'Reminder',
                  Colors.orange,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                  ),
                  onTap: _setReminder,
                ),
                actionButtonCompact(
                  context,
                  Icons.sms,
                  'SMS',
                  Colors.green,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                  ),
                  onTap: _handleSmsButton,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget transactionHeaderRow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 🕓 DATE COLUMN (1.5x)
          Expanded(
            flex: 3, // 1.5x when compared to 2x below
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Date",
                style: GoogleFonts.poppins(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          _buildVerticalDivider(),
          // 💸 DEBIT (1x)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Debit",
                style: GoogleFonts.poppins(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          _buildVerticalDivider(),
          // 💰 CREDIT (1x)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Credit",
                style: GoogleFonts.poppins(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),

          // _buildVerticalDivider(),
          // 🧾 BALANCE (1x)
          // Expanded(
          //   flex: 2,
          //   child: Align(
          //     alignment: Alignment.centerRight,
          //     child: Text(
          //       "Balance",
          //       style: GoogleFonts.poppins(
          //         fontSize: 12 * scale,
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.blue0001,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _handleCallButton() async {
    final phone = _contact.displayPhone;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact'),
        ),
      );
      return;
    }

    // Check phone call permission first
    final permissionUtils = PermissionUtils();
    final hasCallPermission = await permissionUtils.requestCallPhonePermission(
      context,
    );

    if (!hasCallPermission) {
      // Permission denied
      return;
    }

    // Format phone number (remove spaces and special characters)
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    try {
      // Use direct intent URL that bypasses the confirmation dialog
      // First try using the tel: scheme with external application mode
      bool launched = await launchUrl(
        Uri.parse('tel:$formattedPhone'),
        mode: LaunchMode.externalNonBrowserApplication,
      );

      // If the above didn't work, try alternate approach
      if (!launched) {
        await launchUrl(
          Uri.parse('tel:$formattedPhone'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Show error message if dialer can't be opened
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _handlePdfReport() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF report...')),
        );
      }
      // Get transactions
      final transactions = _transactionProvider.getTransactionsForContact(
        _contactId,
      );

      // Prepare data for PDF summary card
      final balance = _calculateBalance();
      final isPositive = balance >= 0;
      bool isWithInterest = _contact.interestType == InterestType.withInterest;

      // Create a more detailed summary with contact information
      final List<Map<String, dynamic>> summaryItems = [
        {'label': 'Name:', 'value': _contact.name},
        {
          'label': 'Phone:',
          'value': _contact.displayPhone ?? _contact.contactId,
        },
        {
          'label': isPositive ? 'YOU WILL GET' : 'YOU WILL GIVE',
          'value': 'Rs. ${PdfTemplateService.formatCurrency(balance.abs())}',
          'highlight': true,
          'isPositive': isPositive,
        },
      ];

      // Add interest information if applicable
      if (isWithInterest) {
        final contactType = _contact.contactType;
        final interestRate = _contact.interestRate;
        final isMonthly = _contact.interestPeriod == InterestPeriod.monthly;

        summaryItems.addAll([
          {
            'label': 'Interest Rate:',
            'value': '$interestRate% ${isMonthly ? 'per month' : 'per annum'}',
          },
          {
            'label': 'Relationship:',
            'value':
            '${StringUtils.capitalizeFirstLetter(contactType.toString())} (${contactType == ContactType.borrower ? 'They borrow from you' : 'You borrow from them'})',
          },
        ]);

        // Calculate interest values
        if (transactions.isNotEmpty) {
          // Calculate principal and interest amounts
          double principalAmount = _contact.principal;

          // // Calculate based on current balance and interest rate
          // principalAmount = balance.abs(); // Use the balance as principal for simplicity

          // Calculate monthly interest
          double monthlyInterest = _contact.interestDue;
          if (isMonthly) {
            monthlyInterest = principalAmount * (interestRate / 100);
          } else {
            // Convert annual rate to monthly
            double monthlyRate = interestRate / 12;
            monthlyInterest = principalAmount * (monthlyRate / 100);
          }

          // Calculate daily interest based on days in current month
          final daysInMonth = DateTime(
            DateTime.now().year,
            DateTime.now().month + 1,
            0,
          ).day;

          summaryItems.addAll([
            {
              'label': 'Estimated Principal:',
              'value':
              'Rs. ${PdfTemplateService.formatCurrency(principalAmount)}',
            },
            {
              'label': 'Est. Monthly Interest:',
              'value':
              'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest)}',
            },
            {
              'label': 'Est. Daily Interest:',
              'value':
              'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest / daysInMonth)}',
            },
          ]);
        }
      }

      // Add transaction stats
      if (transactions.isNotEmpty) {
        final totalPaid = transactions
            .where((tx) => tx.transactionType == 'gave')
            .fold(0.0, (sum, tx) => sum + (tx.amount));

        final totalReceived = transactions
            .where((tx) => tx.transactionType == 'got')
            .fold(0.0, (sum, tx) => sum + (tx.amount));

        final earliestDate = transactions
            .map((tx) => tx.date as DateTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        final latestDate = transactions
            .map((tx) => tx.date as DateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        summaryItems.addAll([
          {'label': 'Total Transactions:', 'value': '${transactions.length}'},
          {
            'label': 'Total Paid:',
            'value': 'Rs. ${PdfTemplateService.formatCurrency(totalPaid)}',
          },
          {
            'label': 'Total Received:',
            'value': 'Rs. ${PdfTemplateService.formatCurrency(totalReceived)}',
          },
          {
            'label': 'First Transaction:',
            'value': DateFormat('dd MMM yyyy').format(earliestDate),
          },
          {
            'label': 'Latest Transaction:',
            'value': DateFormat('dd MMM yyyy').format(latestDate),
          },
        ]);
      }

      // Prepare data for transaction table
      final List<String> tableColumns = ['Date', 'Note', 'Amount', 'Type'];
      final List<List<String>> tableRows = [];

      // Sort transactions by date (newest first)
      final sortedTransactions = List<Transaction>.from(transactions);
      sortedTransactions.sort((a, b) => (b.date).compareTo(a.date));

      for (var transaction in sortedTransactions) {
        final date = DateFormat('dd MMM yyyy').format(transaction.date);

        String note = transaction.note ?? '';
        if (note.isEmpty) {
          note = transaction.transactionType == 'gave'
              ? 'Payment sent'
              : 'Payment received';
        }

        final amount =
            'Rs. ${PdfTemplateService.formatCurrency(transaction.amount)}';
        final type = transaction.transactionType == 'gave'
            ? 'You Paid'
            : 'You Received';

        tableRows.add([date, note, amount, type]);
      }

      // Create PDF content
      final content = [
        // Contact Summary Section
        PdfTemplateService.buildSummaryCard(
          title: 'Contact Summary',
          items: summaryItems,
        ),
        pw.SizedBox(height: 20),

        // Transaction Table
        PdfTemplateService.buildDataTable(
          title: 'Transaction History',
          columns: tableColumns,
          rows: tableRows,
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Date
            1: const pw.FlexColumnWidth(3), // Note
            2: const pw.FlexColumnWidth(1.5), // Amount
            3: const pw.FlexColumnWidth(1.5), // Type
          },
        ),
      ];

      // Generate the PDF document
      final contactName = _contact.name
          .toString()
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final date = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final timestamp = DateFormat('HH_mm_ss').format(DateTime.now());
      final random =
          DateTime.now().millisecondsSinceEpoch % 10000; // Add random component
      final fileName = '${contactName}_report_${date}_${timestamp}_$random.pdf';

      final pdf = await PdfTemplateService.createDocument(
        title: _contact.name,
        subtitle: 'Transaction Report',
        content: content,
        metadata: {
          'keywords':
          'transaction, report, ${_contact.name}, balance, my byaj book',
        },
      );

      // Save and open the PDF
      await PdfTemplateService.saveAndOpenPdf(pdf, fileName);

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF report generated successfully'),
                Text(
                  'Filename: $fileName',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message
      logger.e("error while creating pdf $e");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF report: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _setReminder() async {
    // Check if there's already an active reminder for this contact
    final existingReminder = await _checkForExistingReminder();

    if (existingReminder != null) {
      // Show dialog with options to view, cancel or create new reminder
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          icon: SvgPicture.asset(
            "assets/icons/bells_icon.svg",
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(AppColors.gradientMid, BlendMode.srcIn),
            fit: BoxFit.contain,
          ),
          title: Text(
            'Reminder Already Exists',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You already have a reminder set for ${_contact.name} on:'),
              const SizedBox(height: 8),
              Text(
                DateFormat(
                  'dd MMM yyyy',
                ).format(existingReminder.scheduledDate),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelReminder(existingReminder.reminderId);
              },
              child: Text(
                'Cancel Reminder',
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Keep It',
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showDateTimePickerForReminder();
              },
              child: Text(
                'Set New Reminder',
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // No existing reminder, show date picker directly
    _showDateTimePickerForReminder();
  }

  Future<Reminder?> _checkForExistingReminder() async {
    final List<Reminder> remindersList = _reminderProvider.getReminders(
      _contact.contactId,
    );

    for (final reminder in remindersList) {
      try {
        final scheduledDate = reminder.scheduledDate;
        // Only return if the reminder is in the future
        if (scheduledDate.isAfter(DateTime.now())) {
          return reminder;
        }
      } catch (e) {
        print('Error parsing reminder: $e');
      }
    }
    return null;
  }

  Future<void> _cancelReminder(int reminderId) async {
    // Cancel the notification
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(reminderId);

    try {
      _reminderProvider.removeReminder(reminderId);
    } catch (e) {
      logger.e("in _cancelReminder Error removing reminder: $e");
    }
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder cancelled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDateTimePickerForReminder() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gradientStart, // header & selected date
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gradientStart, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    // 👇 Use builder to override theme colors

    if (selectedDate != null && mounted) {
      // Create a DateTime with just the date component (set time to start of day)
      final scheduledDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // Create a unique ID for this notification based on contact and time
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      // Generate reminder text
      final balance = _calculateBalance();
      final isCredit = _contact.isGet;
      final String reminderText = isCredit
          ? "Reminder to collect ${currencyFormat.format(balance.abs())} from ${_contact.name}"
          : "Reminder to pay ${currencyFormat.format(balance.abs())} to ${_contact.name}";

      // Schedule the notification
      await _scheduleNotification(
        id: notificationId,
        title: "Payment Reminder",
        body: reminderText,
        scheduledDate: scheduledDate,
      );

      // Store reminder details in shared preferences
      await _saveReminderDetails(notificationId, scheduledDate, reminderText);

      // Show confirmation to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _testImmediateNotification() async {
    await _scheduleNotification(
      id: 9999,
      title: "Test Notification",
      body: "This is a test reminder",
      scheduledDate: DateTime.now().add(const Duration(seconds: 10)), // after 10s
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification scheduled in 10 seconds')),
    );
  }

  Future<void> _saveReminderDetails(
      int id,
      DateTime scheduledDate,
      String message,
      ) async {

    Reminder reminder = Reminder(
      contactId: _contactId,
      reminderId: id,
      name : _contact.name,
      scheduledDate: scheduledDate,
      message: message,
      createAt: DateTime.now(),
    );

    await _reminderProvider.addReminder(reminder);

    // Add to list
    // remindersJson.add(jsonEncode(reminder));
    //
    // // Save updated list
    // await prefs.setStringList('contact_reminders', remindersJson);

    // Also notify the NotificationProvider to update UI
    if (mounted) {
      // Add to notification center
      // final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      // notificationProvider.addContactReminderNotification(
      //   contactId: _contact['phone'],
      //   contactName: _contact['name'],
      //   amount: _calculateBalance().abs(),
      //   dueDate: scheduledDate,
      //   paymentType: _calculateBalance() >= 0 ? 'collect' : 'pay',
      // );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // 🕓 Initialize timezone (required)
    tz.initializeTimeZones();
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // 📱 Android details
    const androidDetails = AndroidNotificationDetails(
      'payment_reminders', // channel id
      'Payment Reminders', // channel name
      channelDescription: 'Notifications for payment reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // 🍎 iOS details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 🕓 Schedule the notification at a future date
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // ✅ still valid
    );

    // ✅ Optional: immediate confirmation notification
    await flutterLocalNotificationsPlugin.show(
      id + 1000,
      "Reminder Scheduled",
      "Payment reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}",
      notificationDetails,
    );

    print('✅ Notification scheduled for: $tzScheduledDate');
  }

  void _handleSmsButton() async {
    final balance = _calculateBalance();
    final isPositive = balance >= 0;

    final message =
    '''
Dear ${_contact.name},

🙏 *Payment Reminder*

This is a gentle reminder regarding your account with My Byaj Book:

💰 *Account Summary:*
Current balance: ${currencyFormat.format(balance.abs())}
${isPositive ? '➡️ Payment due to be received' : '➡️ Payment to be made'}

${isPositive ? '✅ Kindly arrange the payment at your earliest convenience.' : '✅ I will arrange the payment shortly.'}

Thank you for your attention to this matter.

Best regards,
${_getAppUserName()} 📱
''';

    bool whatsappOpened = await _tryOpenWhatsApp(message);

    if (!whatsappOpened) {
      await _trySendSMS(message);
    }
  }

  Future<bool> _tryOpenWhatsApp(String message) async {
    final phone = _contact.contactId;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact'),
        ),
      );
      return false;
    }

    // Just get a clean number with no spaces or special chars
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // For India, make sure we have 91 prefix for proper WhatsApp opening
    String whatsappPhone = formattedPhone;
    if (formattedPhone.length == 10) {
      whatsappPhone = "91$formattedPhone";
    }

    // Create the URL
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$whatsappPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      // Launch directly with explicit mode setting
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return true;
    } catch (e) {
      print('Error opening WhatsApp: $e');
      // WhatsApp not installed or couldn't be launched
      return false;
    }
  }

  Future<void> _trySendSMS(String message) async {
    final phone = _contact.contactId;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact'),
        ),
      );
      return;
    }

    // No longer need SMS permission - using intent instead
    // final permissionUtils = PermissionUtils();
    // final hasSmsPermission = await permissionUtils.requestSmsPermission(context);

    // if (!hasSmsPermission) {
    //   // Permission denied
    //   return;
    // }

    // For SMS, keep the + prefix for international numbers
    String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');

    // Create SMS URL
    final smsUrl = Uri.parse(
      'sms:$formattedPhone?body=${Uri.encodeComponent(message)}',
    );

    try {
      // Launch directly without checking canLaunchUrl first
      await launchUrl(smsUrl, mode: LaunchMode.externalNonBrowserApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending SMS: $e')));
    }
  }

  String _getAppUserName() {
    // This should ideally come from user preferences/settings
    // For now, returning a placeholder
    return 'My Byaj Book User';
  }

  // Load updated contact data
  void _loadContact() {
    final provider = Provider.of<TransactionProviderr>(context, listen: false);
    final updatedContact = provider.getContactById(_contact.contactId);
    if (updatedContact != null) {
      setState(() {
        // Replace local reference with fresh one
        _contact = updatedContact;
        // _loadTransactions();
        _filterTransactions();
      });
    } else {
      // Contact might have been deleted
      Navigator.pop(context);
    }
  }

  // Load transactions for the current contact
  void _loadTransactions() {
    _filteredTransactions = _transactionProvider.getTransactionsForContact(
      _contactId,
    );
    _filterTransactions();
  }

  // Method to show the add transaction dialog
  void _showAddTransactionDialog() {
    // Get the relationship type to determine default transaction type
    final ContactType relationshipType = _contact.contactType;

    // For lender contacts, default to "got" (receive) transaction type
    // For borrowers or non-interest contacts, default to "gave" (pay) transaction type
    final String defaultType = relationshipType == ContactType.borrower
        ? 'got'
        : 'gave';

    // Add the transaction with the appropriate type
    _addTransaction(defaultType);
  }

  // void _showContactTypeSelectionDialog(BuildContext context, String name, String phone) {
  //   // Function implementation...
  // }

  // Helper method to build selection buttons for Interest/Principal
  Widget _buildSelectionButton({
    required String title,
    required bool isSelected,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isWithInterest = _contact.interestType != null;
        final relationshipType = _contact.contactType;

        return AlertDialog(
          title: Text('Set Up Your Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ve created a new ${isWithInterest ? "interest-based" : ""} contact.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isWithInterest) ...[
                Row(
                  children: [
                    Icon(
                      relationshipType == 'borrower'
                          ? Icons.person
                          : Icons.account_balance,
                      size: 16,
                      color: relationshipType == 'borrower'
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Relationship: ${StringUtils.capitalizeFirstLetter(relationshipType.name)}',
                      style: GoogleFonts.poppins(
                        color: relationshipType == 'borrower'
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.percent, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Interest Rate: ${_contact.interestRate}% ${_contact.interestPeriod == InterestPeriod.monthly ? 'p.m.' : 'p.a.'}',
                      style: GoogleFonts.poppins(color: Colors.amber.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Next steps:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('1. Add your first transaction'),
                Text('2. Adjust the interest rate if needed'),
                const SizedBox(height: 16),
                Text(
                  'Would you like to do this now?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ] else ...[
                Text('Next step: Add your first transaction'),
                const SizedBox(height: 16),
                Text(
                  'Would you like to add your first transaction now?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isWithInterest) {
                  _showEditInterestRateDialog();
                } else {
                  _addTransaction('gave');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(
                isWithInterest ? 'Set Interest Rate' : 'Add Transaction',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditInterestRateDialog() {
    final TextEditingController interestRateController = TextEditingController(
      text: _contact.interestRate.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Interest Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: interestRateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Interest Rate (% p.a.)',
                hintText: 'Enter interest rate',
                suffixText: '%',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.amber.shade800,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Next, you\'ll need to add your first transaction to start tracking.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // After setting interest rate, prompt for first transaction
              _addTransaction('gave');
            },
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update interest rate
              final newRate =
                  double.tryParse(interestRateController.text) ?? 12.0;
              if (newRate > 0) {
                // Update contact in provider
                final updatedContact = _contact;
                updatedContact.interestRate = newRate;

                _transactionProvider.updateContact(updatedContact);

                // Update local contact data
                setState(() {
                  _contact.interestRate = newRate;
                });

                Navigator.pop(context);

                // After setting interest rate, prompt for first transaction
                _addTransaction('gave');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  // Delete a transaction with confirmation
  // void _confirmDeleteTransaction(Map<String, dynamic> tx, int originalIndex) {
  void _confirmDeleteTransaction(Transaction tx, int originalIndex) {
    if (originalIndex == -1) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this transaction? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Delete the transaction
                _transactionProvider.deleteTransaction(
                  _contactId,
                  originalIndex,
                );

                // Show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        // Re-add the deleted transaction
                        _transactionProvider.addTransaction(_contactId, tx);
                        // _loadTransactions();
                        _filterTransactions();
                      },
                    ),
                  ),
                );

                // Refresh the transactions list
                // _loadTransactions();
                _filterTransactions();

                // Update the contact data
                setState(() {
                  _loadContact();
                });
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Edit an existing transaction
  void _editTransaction(Transaction tx, int originalIndex) {
    if (originalIndex == -1) return;

    final TextEditingController amountController = TextEditingController(
      text: tx.amount.toString(),
    );
    final TextEditingController noteController = TextEditingController(
      text: tx.note,
    );

    String type = tx.transactionType;
    DateTime selectedDate = tx.date;
    List<String> imagePaths = tx.imagePath ?? [];
    String? amountError;

    const double maxAmount = 990000000.0;
    final bool isWithInterest =
        _contact.interestType == InterestType.withInterest;
    final ContactType relationshipType = _contact.contactType;

    bool isPrincipalAmount = tx.isPrincipal;
    final bool showInterestOption =
        isWithInterest &&
            !((relationshipType == ContactType.borrower && type == 'gave') ||
                (relationshipType == ContactType.lender && type == 'got'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: type == 'gave'
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        radius: 14,
                        child: Icon(
                          type == 'gave'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: type == 'gave' ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit ${type == 'gave' ? 'Payment' : 'Receipt'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteTransaction(tx, originalIndex);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount + Date
                  Text(
                    'Amount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            prefixText: '₹ ',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            errorText: amountError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: type == 'gave'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Note + Receipt Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Field
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note (optional)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 80,
                              child: TextField(
                                controller: noteController,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Add a note...',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Receipt Upload
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt (optional)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                _showImageSourceOptions(
                                  context,
                                      (paths) {
                                    setState(() {
                                      imagePaths = paths;
                                      isImageUploading = false;
                                    });
                                  },
                                  setState, // ⭐ PASS BOTTOM SHEET SETSTATE
                                );
                              },
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.gradientMid,
                                    width: 2,
                                  ),
                                ),
                                  child: imagePaths.isNotEmpty
                                      ? GestureDetector(
                                    onTap: () {
                                      _showFullImagesDialog(imagePaths, 0);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(imagePaths.first),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  )
                                      : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 24,
                                          color: type == 'gave'
                                              ? Colors.red.withOpacity(0.7)
                                              : Colors.green.withOpacity(0.7)),
                                      SizedBox(height: 4),
                                      Text("Add receipt"),
                                    ],
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Interest Option
                  if (showInterestOption) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Is this amount for:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSelectionButton(
                          title: 'Interest',
                          isSelected: !isPrincipalAmount,
                          icon: "assets/icons/selected_sip.svg",
                          color: Colors.amber.shade700,
                          onTap: () {
                            setState(() => isPrincipalAmount = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSelectionButton(
                          title: 'Principal',
                          isSelected: isPrincipalAmount,
                          icon: "assets/icons/money_icon.svg",
                          color: Colors.blue,
                          onTap: () {
                            setState(() => isPrincipalAmount = true);
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Transaction Type Toggle
                  Text(
                    'Transaction Type',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => type = 'gave'),
                          icon: const Icon(Icons.arrow_upward, size: 14),
                          label: Text(
                            'PAID',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave'
                                ? Colors.red
                                : Colors.grey.shade300,
                            foregroundColor: type == 'gave'
                                ? Colors.white
                                : Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => type = 'got'),
                          icon: const Icon(Icons.arrow_downward, size: 14),
                          label: Text(
                            'RECEIVED',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'got'
                                ? Colors.green
                                : Colors.grey.shade300,
                            foregroundColor: type == 'got'
                                ? Colors.white
                                : Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 🧠 validation + update logic goes here (same as before)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave'
                                ? Colors.red
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add a method to refresh data
  void _refreshData() {
    if (mounted) {
      _transactionProvider = Provider.of<TransactionProviderr>(
        context,
        listen: false,
      );
      // Reload transactions for this contact
      _filterTransactions();
    }
  }
}
