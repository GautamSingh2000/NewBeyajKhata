import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/Installment.dart';
import '../../data/models/SingleLoan.dart';
import '../../providers/LoanProvider.dart';
import 'AddLoanScreen.dart';

class LoanDetailsScreen extends StatefulWidget {
  final SingleLoan loan;
  final int initialTab;

  const LoanDetailsScreen({
    Key? key,
    required this.loan,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Installment> _installments = [];
  int _paidInstallments = 0;
  bool _showAllInstallments = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadInstallments();
  }

  void _loadInstallments() {
    if (widget.loan.installments != null &&
        widget.loan.installments!.isNotEmpty) {
      _installments = List<Installment>.from(widget.loan.installments!);
      _paidInstallments = _installments.where((i) => i.isPaid).length;
    } else {
      _generateInstallments();
    }
    setState(() {});
  }

  void _generateInstallments() {
    final loanAmount = widget.loan.loanAmount;
    final interestRate = widget.loan.interestRate / 100;
    final loanTerm = widget.loan.loanTerm;

    final monthlyRate = interestRate / 12;
    final emi = loanAmount *
        monthlyRate *
        pow(1 + monthlyRate, loanTerm) /
        (pow(1 + monthlyRate, loanTerm) - 1);

    double remainingAmount = loanAmount;
    DateTime paymentDate = widget.loan.firstPaymentDate;

    final newList = <Installment>[];

    for (int i = 0; i < loanTerm; i++) {
      final interestForMonth = remainingAmount * monthlyRate;
      final principalForMonth = emi - interestForMonth;
      remainingAmount -= principalForMonth;

      newList.add(
        Installment(
          installmentNumber: i + 1,
          dueDate: paymentDate,
          totalAmount: emi,
          principal: principalForMonth,
          interest: interestForMonth,
          remainingAmount: remainingAmount > 0 ? remainingAmount : 0,
        ),
      );

      paymentDate = DateTime(paymentDate.year, paymentDate.month + 1, paymentDate.day);
    }

    widget.loan.installments = newList;
    _installments = newList;

    Provider.of<LoanProvider>(context, listen: false).updateLoanModel(widget.loan);
  }

  void _markAsPaid(int index) {
    final now = DateTime.now();

    setState(() {
      _installments[index].isPaid = true;
      _installments[index].paidDate = now;

      _paidInstallments = _installments.where((i) => i.isPaid).length;
      widget.loan.progress = _paidInstallments / _installments.length;

      if (widget.loan.progress == 1.0) {
        widget.loan.status = "Completed";
        widget.loan.completionDate = now;
      }

      widget.loan.installments = _installments;
    });

    Provider.of<LoanProvider>(context, listen: false).updateLoanModel(widget.loan);
  }

  void _undoPayment(int index) {
    setState(() {
      _installments[index].isPaid = false;
      _installments[index].paidDate = null;

      _paidInstallments = _installments.where((i) => i.isPaid).length;
      widget.loan.progress = _paidInstallments / _installments.length;

      if (widget.loan.status == "Completed") {
        widget.loan.status = "Active";
        widget.loan.completionDate = null;
      }

      widget.loan.installments = _installments;
    });

    Provider.of<LoanProvider>(context, listen: false).updateLoanModel(widget.loan);
  }

  void _selectPaymentDate(int index) async {
    if (!_installments[index].isPaid) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _installments[index].paidDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _installments[index].paidDate = picked;
        widget.loan.installments = _installments;
      });

      Provider.of<LoanProvider>(context, listen: false).updateLoanModel(widget.loan);
    }
  }

  double get _progressPercentage =>
      _installments.isEmpty ? 0 : _paidInstallments / _installments.length;

  double _getTotalPaidAmount() =>
      _installments.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.totalAmount);

  double _getTotalRemainingAmount() =>
      _installments.where((i) => !i.isPaid).fold(0.0, (sum, i) => sum + i.totalAmount);

  double _getTotalInterest() =>
      _installments.fold(0.0, (sum, i) => sum + i.interest);

  @override
  Widget build(BuildContext context) {
    final loanName = widget.loan.loanName;

    return Scaffold(
        resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        title: Text(loanName, style: const TextStyle(color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "SUMMARY"),
            Tab(text: "PAYMENTS"),
            Tab(text: "DETAILS"),
          ],
        ),
      ),
      body: Container(
        color: Colors.blue.shade50.withOpacity(0.5),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildPaymentsTab(),
            _buildDetailsTab(),
          ],
        ),
      )
    );
  }

  Widget _buildSummaryTab() {
    final totalEmis = _installments.length;
    final emi = _installments.isNotEmpty ? _installments[0].totalAmount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Loan Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("${(_progressPercentage * 100).toStringAsFixed(1)}% Paid"),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _progressPercentage,
                    minHeight: 8,
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Text("$_paidInstallments of $totalEmis EMIs"),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _summaryCard("assets/icons/loan_amount.svg", "Loan Amount", "₹${widget.loan.loanAmount.toStringAsFixed(2)}", Colors.blue)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryCard("assets/icons/calendar.svg", "Monthly EMI", "₹${emi.toStringAsFixed(2)}", Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summaryCard("assets/icons/ic_check.svg", "Paid So Far", "₹${_getTotalPaidAmount().toStringAsFixed(2)}", Colors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryCard("assets/icons/loan_tenure.svg", "Remaining", "₹${_getTotalRemainingAmount().toStringAsFixed(2)}", Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Upcoming Payments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ..._installments.where((i) => !i.isPaid).take(3).map(_buildUpcomingPaymentItem),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildPaymentBreakdown(),
        ],
      ),
    );
  }

  Widget _summaryCard(String icon, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            color,
            BlendMode.srcIn,
          ),
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _buildUpcomingPaymentItem(Installment inst) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              "assets/icons/calendar.svg",
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(Colors.blue.shade600, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Installment #${inst.installmentNumber}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("Due on ${_format(inst.dueDate)}",
                  style: TextStyle(color: Colors.grey.shade600))
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("₹${inst.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Text("Upcoming",
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 11)),
            )
          ])
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Payment Breakdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Principal", style: TextStyle(color: Colors.grey)),
              Text("Interest", style: TextStyle(color: Colors.grey)),
              Text("Total", style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("₹${widget.loan.loanAmount.toStringAsFixed(2)}",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text("₹${_getTotalInterest().toStringAsFixed(2)}",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
                "₹${(widget.loan.loanAmount + _getTotalInterest()).toStringAsFixed(2)}",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ])
        ]),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final total = _installments.length;
    final displayCount = _showAllInstallments ? total : (total <= 10 ? total : 10);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Showing $displayCount of $total payments",
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            if (total > 10)
              TextButton(
                onPressed: () =>
                    setState(() => _showAllInstallments = !_showAllInstallments),
                child: Text(_showAllInstallments ? "Show Less" : "Show All",
                    style: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ..._installments
            .take(displayCount)
            .map((installment) => _paymentCard(installment))
            .toList(),
      ]),
    );
  }

  Widget _paymentCard(Installment inst) {
    final index = _installments.indexOf(inst);
    final isPaid = inst.isPaid;
    final formattedDue = _format(inst.dueDate);
    final formattedPaid = inst.paidDate != null ? _format(inst.paidDate) : null;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isPaid ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Installment ${inst.installmentNumber}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(isPaid ? "Paid" : "Pending",
                  style: GoogleFonts.poppins(
                    fontSize: context.screenWidth * 0.025,
                      color: isPaid
                          ? Colors.green.shade800
                          : Colors.orange.shade800)),
            )
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Amount", style: GoogleFonts.poppins(color: Colors.grey, fontSize: context.screenHeight * 0.017)),
              Text("₹${inst.totalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: context.screenWidth * 0.04)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Text("Due Date", style: GoogleFonts.poppins(color: Colors.grey,fontSize: context.screenWidth*0.03)),
              Text(formattedDue,
                  style: GoogleFonts.poppins(
                      fontSize: context.screenWidth * 0.027,
                      color: isPaid ? Colors.grey : Colors.red)),
            ]),
            if (isPaid && formattedPaid != null)
              Column(
                children: [
                  const Text("Paid On", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => _selectPaymentDate(index),
                    child: Row(
                      children: [
                        Text(formattedPaid,
                            style: GoogleFonts.poppins(color: Colors.green)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 14, color: Colors.blue)
                      ],
                    ),
                  ),
                ],
              ),
          ]),
          const SizedBox(height: 16),
          if (!isPaid)
            ElevatedButton.icon(
              onPressed: () => _markAsPaid(index),
              icon: const Icon(Icons.check_circle_outline,color: Colors.white,),
              label: Text(
                "Mark as Paid",
                style: GoogleFonts.poppins(
                  color: Colors.white
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // 🔥 Change radius here
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _undoPayment(index),
              icon: const Icon(Icons.undo),
              label: const Text("Undo"),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 40)),
            ),
        ]),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue.shade700),
                title: Text(
                  'Edit Loan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editLoan();
                },
              ),
              ListTile(
                leading: Icon(Icons.pause_circle_outline, color: Colors.orange.shade700),
                title: Text(
                  'Mark as Inactive',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markLoanAsInactive();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Delete Loan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.red, // Matches delete icon theme
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _markLoanAsInactive() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Mark Loan as Inactive',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to mark this loan as inactive? You can reactivate it later from the archive.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                final loanProvider = Provider.of<LoanProvider>(context, listen: false);
                widget.loan.status = "Inactive";

                loanProvider.updateLoanModel(widget.loan);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Loan marked as inactive',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );

                Navigator.pop(context, true);
              },
              child: Text(
                'CONFIRM',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Delete Loan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete this loan? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLoan();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'DELETE',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLoan() async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final loanId = widget.loan.id; // ✔ now using model

    // Delete the loan
    final success = await loanProvider.deleteLoanModel(loanId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loan deleted successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate back
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete loan")),
      );
    }
    // Show confirmation

  }

  void _editLoan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddLoanScreen(
          isEditing: true,
          loan: widget.loan, // now passing model instead of map
        ),
      ),
    );

    if (result == true) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final updatedLoan = loanProvider.getLoanById(widget.loan.id);

      if (updatedLoan != null) {
        setState(() {
          widget.loan.loanName = updatedLoan.loanName;
          widget.loan.loanAmount = updatedLoan.loanAmount;
          widget.loan.interestRate = updatedLoan.interestRate;
          widget.loan.loanTerm = updatedLoan.loanTerm;
          widget.loan.firstPaymentDate = updatedLoan.firstPaymentDate;
          widget.loan.installments = updatedLoan.installments;

          /// if core loan values changed → regenerate EMIs
          bool requiresRebuild = widget.loan.loanAmount != updatedLoan.loanAmount ||
              widget.loan.interestRate != updatedLoan.interestRate ||
              widget.loan.loanTerm != updatedLoan.loanTerm;

          if (requiresRebuild) _generateInstallments();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan updated successfully',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildDetailsTab() {
    final loan = widget.loan;
    final emi = _installments.isNotEmpty ? _installments[0].totalAmount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Loan Details",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 18)),
              const SizedBox(height: 20),
              _row("Loan Name", loan.loanName),
              _row("Loan Type", loan.loanType),
              _row("Loan Amount", "₹${loan.loanAmount.toStringAsFixed(2)}"),
              _row("Interest Rate", "${loan.interestRate}% (Fixed)"),
              _row("Loan Term", "${loan.loanTerm} months"),
              _row("EMI Amount", "₹${emi.toStringAsFixed(2)}"),
              _row("Total Interest", "₹${_getTotalInterest().toStringAsFixed(2)}"),
              _row(
                  "Total Amount",
                  "₹${(loan.loanAmount + _getTotalInterest()).toStringAsFixed(2)}"),
              _row("Start Date", _format(loan.startAt)),
              _row("First Payment", _format(loan.firstPaymentDate)),
              _row("Status", loan.status),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("Payment Statistics",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 18)),
              const SizedBox(height: 20),
              _row("Total EMIs", "${_installments.length}"),
              _row("EMIs Paid", "$_paidInstallments"),
              _row("EMIs Remaining",
                  "${_installments.length - _paidInstallments}"),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style:  GoogleFonts.poppins(color: Colors.grey.shade600,fontSize: context.screenWidth * 0.03)),
      Text(value, style:  GoogleFonts.poppins(fontWeight: FontWeight.w500 , fontSize: context.screenWidth * 0.03)),
    ]),
  );

  String _format(DateTime? d) =>
      "${d!.day} ${_monthNames[d.month - 1]} ${d.year}";

  static const _monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
}

double pow(double x, int y) {
  double r = 1;
  for (int i = 0; i < y; i++) r *= x;
  return r;
}
