import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/SingleLoan.dart';
import '../../providers/LoanProvider.dart';

class AddLoanScreen extends StatefulWidget {
  final bool isEditing;
  final SingleLoan? loan;

  const AddLoanScreen({
    super.key,
    this.isEditing = false,
    this.loan,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loanNameController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _loanProviderController = TextEditingController();
  final _loanNumberController = TextEditingController();
  final _helplineNumberController = TextEditingController();
  final _managerNumberController = TextEditingController();

  String _selectedLoanType = "Home Loan";
  String _selectedInterestType = "Fixed";
  String _selectedPeriodType = "Years";
  String _selectedPaymentMethod = "UPI";

  DateTime _loanStartDate = DateTime.now();
  DateTime _firstPaymentDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.loan != null) {
      final loan = widget.loan!;
      _loanNameController.text = loan.loanName;
      _loanAmountController.text = loan.loanAmount.toString();
      _interestRateController.text = loan.interestRate.toString();
      _loanProviderController.text = loan.loanProvider ?? "";
      _loanNumberController.text = loan.loanNumber ?? "";
      _helplineNumberController.text = loan.helplineNumber ?? "";
      _managerNumberController.text = loan.managerNumber ?? "";
      _selectedLoanType = loan.loanType;
      _selectedInterestType = loan.interestType;
      _selectedPaymentMethod = loan.paymentMethod;
      _loanStartDate = loan.startAt;
      _firstPaymentDate = loan.firstPaymentDate;

      if (loan.loanTerm % 12 == 0) {
        _selectedPeriodType = "Years";
        _tenureController.text = (loan.loanTerm ~/ 12).toString();
      } else {
        _selectedPeriodType = "Months";
        _tenureController.text = loan.loanTerm.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoanProvider>(context, listen: false);

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
            Navigator.pop(context); // or your own logic
          },
        ),
        title: Text(widget.isEditing ? "Edit Loan" : "Add Loan" , style: GoogleFonts.poppins(
          fontSize: context.screenWidth * 0.045,
              color: Colors.white
        ),),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _textField(_loanNameController, "Loan Name", "assets/icons/loan_name.svg"),
              const SizedBox(height: 14),

              _dropdown(
                label: "Loan Type",
                value: _selectedLoanType,
                getLoanIcon: getLoanIcon,
                items: const ["Home Loan", "Personal Loan", "Car Loan", "Education Loan", "Business Loan"],
                onChanged: (v) => setState(() => _selectedLoanType = v!),

                prefixIconPath: "assets/icons/loan_type.svg",
              ),
              const SizedBox(height: 14),

              _textField(_loanProviderController, "Loan Provider", "assets/icons/loan_provider.svg", required: false),
              const SizedBox(height: 14),

              _textField(_loanNumberController, "Loan Account Number", "assets/icons/loan_account.svg", required: false),
              const SizedBox(height: 20),

              _textField(_loanAmountController, "Loan Amount", "assets/icons/loan_amount.svg", keyboard: TextInputType.number),
              const SizedBox(height: 14),

              _textField(_interestRateController, "Interest Rate (%)", "assets/icons/interest_rate.svg", keyboard: TextInputType.number),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _textField(_tenureController, "Tenure", "assets/icons/loan_tenure.svg", keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown(
                      label: "Period",
                      value: _selectedPeriodType,
                      items: const ["Years", "Months"],
                      onChanged: (v) => setState(() => _selectedPeriodType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _dateField("Loan Start Date", _loanStartDate, () => _pickDate(true)),
              const SizedBox(height: 14),

              _dateField("First Payment Date", _firstPaymentDate, () => _pickDate(false)),
              const SizedBox(height: 20),

              _dropdown(
                label: "Payment Method",
                value: _selectedPaymentMethod,
                items: const ["UPI", "Bank Transfer", "Auto Debit", "Cheque", "Cash"],
                onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
              ),
              const SizedBox(height: 14),

              _textField(_helplineNumberController, "Helpline Number", "assets/icons/helpline.svg", keyboard: TextInputType.phone, required: false),
              const SizedBox(height: 14),

              _textField(_managerNumberController, "Manager Number", "assets/icons/manager.svg", keyboard: TextInputType.phone, required: false),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,      // text color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _save(provider),
                child: Text(widget.isEditing ? "Update Loan" : "Save Loan", style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: context.screenWidth * 0.03
                ),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // SAVE LOAN LOGIC
  // --------------------------------------------------------------
  Future<void> _save(LoanProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_loanAmountController.text) ?? 0;
    final rate = double.tryParse(_interestRateController.text) ?? 0;
    final tenureMonths = _selectedPeriodType == "Years"
        ? (int.parse(_tenureController.text) * 12)
        : int.parse(_tenureController.text);

    if (widget.isEditing && widget.loan != null) {
      final updated = SingleLoan(
        id: widget.loan!.id,
        loanType: _selectedLoanType,
        category: _selectedLoanType.split(" ").first,
        loanAmount: amount,
        interestRate: rate,
        loanTerm: tenureMonths,
        status: widget.loan!.status,
        progress: widget.loan!.progress,
        startAt: _loanStartDate,
        firstPaymentDate: _firstPaymentDate,
        createdDate: widget.loan!.createdDate,
        completionDate: widget.loan!.completionDate,
        installments: widget.loan!.installments,
        loanName: _loanNameController.text,
        loanProvider: _loanProviderController.text,
        loanNumber: _loanNumberController.text,
        helplineNumber: _helplineNumberController.text,
        managerNumber: _managerNumberController.text,
        paymentMethod: _selectedPaymentMethod,
        interestType: _selectedInterestType,
      );
      provider.updateLoanModel(updated);
      Navigator.pop(context);
    } else {
      final newLoan = SingleLoan(
        id: _loanNameController.text+DateTime.now().millisecondsSinceEpoch.toString(),
        loanType: _selectedLoanType,
        category: _selectedLoanType.split(" ").first,
        loanAmount: amount,
        interestRate: rate,
        loanTerm: tenureMonths,
        startAt: _loanStartDate,
        firstPaymentDate: _firstPaymentDate,
        createdDate: DateTime.now(),
        completionDate: null,
        status: "Active",
        progress: 0.0,
        installments: [],
        loanName: _loanNameController.text,
        loanProvider: _loanProviderController.text,
        loanNumber: _loanNumberController.text,
        helplineNumber: _helplineNumberController.text,
        managerNumber: _managerNumberController.text,
        paymentMethod: _selectedPaymentMethod,
        interestType: _selectedInterestType,
      );
      final success = await provider.addLoanModel(newLoan);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loan added successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add loan")),
        );
      }
    }
  }

  // --------------------------------------------------------------
  // UI WIDGETS
  // --------------------------------------------------------------

  Widget _textField(TextEditingController c, String label, String iconPath, {
    bool required = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        // NORMAL BORDER
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.grey,   // border when not focused
            width: 1.2,
          ),
        ),

        // FOCUSED BORDER
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,   // border color on focus
            width: 1.8,
          ),
        ),

        // ERROR BORDER
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),

        // FOCUSED + ERROR BORDER
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.8,
          ),
        ),
        // Usage of the custom widget ensures color changes on focus
        prefixIcon: FormSvgIcon(assetPath: iconPath),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey,   // normal label color
        ),
        floatingLabelStyle: GoogleFonts.poppins(
        color: AppColors.primaryColor,   // your active color
        fontWeight: FontWeight.w600,
      ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.primaryColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (v) => v == null || v.isEmpty ? "Enter $label" : null
          : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData Function(String)? getLoanIcon,

    String prefixIconPath = "assets/icons/dropdown_icon.svg",
    Color bgColor = Colors.white,
    Color textColor = Colors.black,
    Color focusColor = Colors.blue,
  }) {
    return DropdownButtonFormField<String>(
      value: value,

      icon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SvgPicture.asset(
          "assets/icons/arrow_down.svg",
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        ),
      ),

      decoration: InputDecoration(
        filled: true,
        fillColor: bgColor,
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.6)),
        floatingLabelStyle: GoogleFonts.poppins(
          color: focusColor,
          fontWeight: FontWeight.w600,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.8),
        ),
      ),

      dropdownColor: bgColor,
      style: GoogleFonts.poppins(color: textColor, fontSize: 14),

      items: items
          .map(
            (loanType) => DropdownMenuItem(
              value: loanType,
              child: Row(
                children: [
                  if (getLoanIcon != null) ...[
                    Icon(
                      getLoanIcon!(loanType),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                  ],
              Text(
                loanType,
                style: GoogleFonts.poppins(color: textColor),
              ),
            ],
          ),
        ),
      )
          .toList(),

      onChanged: onChanged,
    );
  }


  IconData getLoanIcon(String loanType) {
    switch (loanType) {
      case 'Home Loan':
        return Icons.home;
      case 'Car Loan':
        return Icons.directions_car;
      case 'Personal Loan':
        return Icons.person;
      case 'Education Loan':
        return Icons.school;
      case 'Business Loan':
        return Icons.business;
      default:
        return Icons.account_balance;
    }
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    // Note: Date fields are custom containers, so we manually use 'primary' color
    // here or keep it grey. To make it consistent, we stick to grey-700.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade500), // Standard border
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              "assets/icons/calendar_date.svg",
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(Colors.grey.shade700, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            Text("$label:  ${date.day}-${date.month}-${date.year}"),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _loanStartDate : _firstPaymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _loanStartDate = picked;
          _firstPaymentDate = DateTime(picked.year, picked.month + 1, picked.day);
        } else {
          _firstPaymentDate = picked;
        }
      });
    }
  }
}

// --------------------------------------------------------------
// CUSTOM ICON WIDGET (HANDLES FOCUS COLOR AUTOMATICALLY)
// --------------------------------------------------------------
class FormSvgIcon extends StatelessWidget {
  final String assetPath;

  const FormSvgIcon({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    // This context is inside the TextFormField, so it knows about Focus state!
    final IconThemeData iconTheme = IconTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SvgPicture.asset(
        assetPath,
        width: 24,
        height: 24,
        // Use the color provided by InputDecorator (Grey if idle, Blue if focused)
        colorFilter: ColorFilter.mode(
            iconTheme.color ?? Colors.grey.shade700,
            BlendMode.srcIn
        ),
      ),
    );
  }
}