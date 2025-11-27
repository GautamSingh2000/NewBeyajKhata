import 'dart:io';
import 'dart:math';

import 'package:byaj_khata_book/core/constants/ContactType.dart';
import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/data/models/Contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../../core/constants/InterestPeriod.dart';
import '../../core/constants/InterestType.dart';
import '../../core/constants/RouteNames.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../providers/TransactionProviderr.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ConfirmDialog.dart';

class EditContactScreen extends StatefulWidget {
  final Contact contact;
  final bool isWithInterest;

  const EditContactScreen({
    super.key,
    required this.contact,
    required this.isWithInterest,
  });

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _principalController = TextEditingController();
  bool _isWithInterest = false;
  final _interestRateController = TextEditingController();
  ContactType _selectedType = ContactType.borrower;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
  File? _profileImage;
  bool _isDeleteLoading = false;

  // Add interest rate period selector (monthly or yearly)
  InterestPeriod _interestPeriod = InterestPeriod.yearly; // 'monthly' or 'yearly'

  late TransactionProviderr _transactionProvider;

  String get _contactId => widget.contact.contactId;

  void initState() {
    super.initState();
    // Initialize controllers with existing contact data
    _nameController.text = widget.contact.name ?? '';
    _phoneController.text = widget.contact.displayPhone ?? '';

    // Check if this is a with-interest contact
    _isWithInterest = widget.isWithInterest;

    if (_isWithInterest) {
      _selectedType = widget.contact.contactType;
      _principalController.text = widget.contact.principal.toString();
      _interestRateController.text = widget.contact.interestRate.toString();
      _interestPeriod = widget.contact.interestPeriod ?? InterestPeriod.yearly;
    }

    // Initialize profile image if it exists
    if (widget.contact.profileImage != null) {
      _profileImage = File(widget.contact.profileImage!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the provided transaction provider if available, otherwise get from context
    _transactionProvider = Provider.of<TransactionProviderr>(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  void _showProfileImageOptions() async {
    final imagePickerHelper = ImagePickerHelper();
    final File? result = await imagePickerHelper.showImageSourceDialog(
      context,
      currentImage: _profileImage,
    );

    // If result is null, user might have pressed "Remove"
    if (result != null) {
      setState(() {
        _profileImage = result;
      });
    } else if (result == null && mounted) {}
  }

  Future<void> _updateContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String initials = _nameController.text.isNotEmpty
        ? _nameController.text
              .substring(0, min(2, _nameController.text.length))
              .toUpperCase()
        : widget.contact.initials;

    final updatedContact = Contact(
      initials: initials,
      colorValue: Colors.primaries["Alice".length % Colors.primaries.length].value,
      displayAmount: _principalController.text.trim().isNotEmpty
          ? double.tryParse(_principalController.text.trim()) ?? 0.0 : widget.contact.principal,
      isGet: _selectedType == ContactType.borrower ? true : false,
      dayAgo: 0,
      lastEditedAt: DateTime.now(),
      contactId: widget.contact.contactId,
      name: _nameController.text.trim(),
      displayPhone: _phoneController.text.trim(),
      principal: _principalController.text.trim().isNotEmpty
          ? double.tryParse(_principalController.text.trim()) ?? 0.0 : widget.contact.principal,
      profileImage: _profileImage?.path,
      contactType: _selectedType,
      isNewContact: true,
      interestType: _isWithInterest ? InterestType.withInterest : InterestType.withoutInterest,
      interestRate: _isWithInterest
          ? double.tryParse(_interestRateController.text) ?? 0.0
          : widget.contact.interestRate,
      interestPeriod: _isWithInterest ? _interestPeriod : null,
    );
    final success = await _transactionProvider.addContact(updatedContact);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully')),
      );

      // If this is a new contact, automatically navigate to the transaction entry dialog
      if (widget.contact.isNewContact == true) {
        // Short delay to allow the previous screen to process the result
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          Logger log = Logger();
          log.e("Navigating to details of contact: ${updatedContact.name} with interest type ${widget.isWithInterest}");
          // Find the ContactDetailScreen and show the transaction entry dialog
          context.push<Contact>(
            RouteNames.contestDetails,
            extra: {
              'isWithInterest': widget.isWithInterest,
              'contactId': updatedContact.contactId,
              'showTransactionDialogOnLoad': true,
            }, // pass the contact as extra
          );
        });
      }else{
        Logger log = Logger();
        log.e("not navigating to details of contact: ${updatedContact.name} with interest type ${widget.isWithInterest}");
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update contact')));
    }
    // Return true to the previous screen to indicate successful update
    Navigator.pop(context, true);
  }

  Future<void> _deleteContact() async {
    setState(() {
      _isDeleteLoading = true;
    });

    try {
      // Make sure contact exists in the contacts list
      final contactExists =
          _transactionProvider.getContactById(_contactId) != null;

      if (!contactExists) {
        // First add the contact to ensure it exists
        // await _transactionProvider.addContact(widget.contact);
        final success = await _transactionProvider.deleteContact(_contactId);

        if (success && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.contact.name} deleted')),
          );

          // Navigate all the way back to home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
    } catch (e) {
      // Removed debug print
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteLoading = false;
        });
      }
    }

    // Show error message if we reach here
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete contact')));
    }
  }

  void _confirmDeleteContact() {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Contact',
        content:
            'Are you sure you want to delete ${widget.contact.name}? This will delete all transaction history.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: _deleteContact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hasTransactions = _transactionProvider
        .getTransactionsForContact(_contactId)
        .isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        automaticallyImplyLeading: false,
        // Custom leading widget
        leading: IconButton(
          icon: SvgPicture.asset(
            "assets/icons/left_icon.svg",
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            fit: BoxFit.contain,
          ),
          // 👈 change icon & color
          onPressed: () {
            Navigator.pop(context); // or your own logic
          },
        ),
        title: Text(
          'Edit Contact',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Add delete button to app bar
          IconButton(
            icon: _isDeleteLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    "assets/icons/delete_icon.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.contain,
                  ),
            onPressed: _isDeleteLoading ? null : _confirmDeleteContact,
            tooltip: 'Delete Contact',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50, // Smaller radius to save space
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      fontSize: 50,
                                      color: Colors.grey.shade400,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showProfileImageOptions,
                              child: CircleAvatar(
                                backgroundColor: themeProvider.primaryColor,
                                radius: 18,
                                child: SvgPicture.asset(
                                  "assets/icons/camera.svg",
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Balance information removed per request

                    // Name Field
                    Text(
                      'Name',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter contact name',
                        hintStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor, // color when focused
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red, // color when error
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone Field
                    Text(
                      'Phone Number',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor, // color when focused
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red, // color when error
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category has been removed
                    // const SizedBox(height: 16),

                    // With Interest Toggle
                    Row(
                      children: [
                        Text(
                          'With Interest Account',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isWithInterest,
                          onChanged: hasTransactions && !_isWithInterest
                              ? null // Disable converting to interest if there are transactions and it's not already interest
                              : (value) {
                                  setState(() {
                                    _isWithInterest = value;

                                    // If switching to with-interest, set default values
                                    if (value &&
                                        _interestRateController.text.isEmpty) {
                                      _interestRateController.text =
                                          '12.0'; // Default interest rate
                                    }
                                  });
                                },
                          activeColor: themeProvider.primaryColor,
                        ),
                      ],
                    ),
                    if (hasTransactions && !_isWithInterest)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Cannot convert to interest account after transactions',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (_isWithInterest)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Specify if this contact is a borrower (owes you money) or lender (you owe them)',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Interest Rate and Type (Only if with interest)
                    if (_isWithInterest) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Interest Rate',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _interestRateController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter rate',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red, // color when error
                                        width: 1,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    suffixText: '%',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    if (_isWithInterest) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a rate';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Enter a valid number';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Per Period',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _interestPeriod =
                                                  InterestPeriod.monthly;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _interestPeriod ==
                                                      InterestPeriod.monthly
                                                  ? Colors.amber.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    left: Radius.circular(7),
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Monthly',
                                              style: GoogleFonts.poppins(
                                                fontWeight:
                                                    _interestPeriod ==
                                                        InterestPeriod.monthly
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    _interestPeriod ==
                                                        InterestPeriod.monthly
                                                    ? Colors.amber.shade900
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade400,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _interestPeriod =
                                                  InterestPeriod.yearly;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _interestPeriod ==
                                                      InterestPeriod.yearly
                                                  ? Colors.amber.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(7),
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Yearly',
                                              style: GoogleFonts.poppins(
                                                fontWeight:
                                                    _interestPeriod ==
                                                        InterestPeriod.yearly
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    _interestPeriod ==
                                                        InterestPeriod.yearly
                                                    ? Colors.amber.shade900
                                                    : Colors.grey.shade700,
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Principle Amount',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _principalController,
                        decoration: InputDecoration(
                          hintText: 'Enter Principle Amount',
                          hintStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor, // color when focused
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red, // color when error
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Account Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          // Borrower Option
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == ContactType.borrower
                                  ? Colors.red.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == ContactType.borrower
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: _selectedType == ContactType.borrower
                                    ? 2
                                    : 1,
                              ),
                              boxShadow: _selectedType == ContactType.borrower
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = ContactType.borrower;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: SvgPicture.asset(
                                            "assets/icons/wallet.svg",
                                            width: 20,
                                            height: 20,
                                            colorFilter: ColorFilter.mode(
                                              Colors.red,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Jisne Paise Liye Hai',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Radio<ContactType>(
                                                        value: ContactType
                                                            .borrower,
                                                        groupValue:
                                                            _selectedType,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedType =
                                                                value!;
                                                          });
                                                        },
                                                        activeColor: Colors.red,
                                                      ),
                                                      Text(
                                                        'Borrower',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors.red,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'वह आपका पैसा लेकर देनदार है',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'This contact owes you money',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Lender Option
                          Container(
                            decoration: BoxDecoration(
                              color: _selectedType == ContactType.lender
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == ContactType.lender
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: _selectedType == ContactType.lender
                                    ? 2
                                    : 1,
                              ),
                              boxShadow: _selectedType == ContactType.lender
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = ContactType.lender;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.account_balance,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Jisne Paise Diye Hai',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Radio<ContactType>(
                                                        value:
                                                            ContactType.lender,
                                                        groupValue:
                                                            _selectedType,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedType =
                                                                value!;
                                                          });
                                                        },
                                                        activeColor:
                                                            Colors.green,
                                                      ),
                                                      Text(
                                                        'Lender',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'आपने इनसे पैसे उधार लिए हैं',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'You owe money to this contact',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Save Button bottom bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.0),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _updateContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
