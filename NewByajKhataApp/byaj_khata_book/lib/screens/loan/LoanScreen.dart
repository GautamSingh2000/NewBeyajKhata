import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
import 'package:byaj_khata_book/data/models/LoanSummary.dart';
import 'package:byaj_khata_book/providers/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/SingleLoan.dart';
import '../../providers/LoanProvider.dart';
import '../../widgets/LoanSummaryCard.dart';
import 'AddLoanScreen.dart';
import 'LoanDetailsScreen.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String _selectedCategory = 'All';

  // Helper function to calculate power of a number
  static double _pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadLoanData();
  }


  void _loadLoanData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still mounted before accessing the provider
      if (!mounted) return;

      try {
        // Get the provider, handling possible exceptions
        final provider = Provider.of<LoanProvider>(context, listen: false);
        provider.loadLoans();
      } catch (e) {
        // Removed debug print
      }
    });
  }

  List<SingleLoan> get _filteredLoans {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (_selectedCategory == 'All') {
      return loanProvider.activeLoans;
    } else {
      return loanProvider.activeLoans.where((loan) =>
      loan.category == _selectedCategory ||
          loan.loanType == '$_selectedCategory Loan').toList();
    }
  }


  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<LoanProvider>(
          builder: (context, loanProvider, _) {
            try {
              // Get user provider to pass to loan summary
              final userProvider = Provider.of<UserProvider>(
                  context, listen: false);

              // Get loan summary data with user info, filtered by category
              LoanSummary summaryData = loanProvider.getLoanSummary(
                  userProvider);

              return Scaffold(
                backgroundColor: Colors.white,
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoanSummaryCard(
                          userName: summaryData.userName,
                          activeLoans: summaryData.activeLoans,
                          totalAmount: summaryData.totalAmount,
                          dueAmount: summaryData.dueAmount,
                        ),
                        const SizedBox(height: 16),
                        _buildLoanTypeFilters(),
                        const SizedBox(height: 16),
                        _buildActiveLoansList(loanProvider),
                      ],
                    ),
                  ),
                ),
              );
            } catch (e) {
              // Removed debug print
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading loan data',
                          style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(e.toString(),
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Go Back', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
      );
    } catch (e) {
      // Removed debug print
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Critical Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(e.toString(),
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back', style: GoogleFonts.poppins(),),
              ),
            ],
          ),
        ),
      );
    }
  }


  Widget _buildActiveLoansList(LoanProvider loanProvider) {
    if (loanProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loanProvider.activeLoans.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredLoans.isEmpty && _selectedCategory != 'All') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No loans in $_selectedCategory category',
              style: GoogleFonts.poppins(
                fontSize: context.screenWidth * 0.045,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: GoogleFonts.poppins(
                fontSize: context.screenWidth * 0.035,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLoanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label:  Text('Add Loan',  style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == 'All' ? 'All Loans' : '$_selectedCategory Loans',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLoanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('New Loan',  style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _filteredLoans.length,
          itemBuilder: (context, index) {
            return _buildLoanCard(_filteredLoans[index]);
          },
        ),
      ],
    );
  }

  Widget _buildLoanCard(SingleLoan loan) {
    final Color loanColor = _getLoanColor(loan.loanType ?? "");
    final IconData loanIcon = _getLoanIcon(loan.loanType ?? "");

    bool isCurrentMonthEmiPaid = false;
    DateTime? nextPaymentDate;

    // ---------------------------
    // 🔹 Handle Installments (Model Version)
    // ---------------------------
    if (loan.installments != null && loan.installments!.isNotEmpty) {
      final now = DateTime.now();

      // 1) Check if current month's EMI is paid
      for (final inst in loan.installments!) {
        if (inst.dueDate != null &&
            inst.dueDate!.month == now.month &&
            inst.dueDate!.year == now.year) {
          isCurrentMonthEmiPaid = inst.isPaid;
          break;
        }
      }

      // 2) Find next unpaid EMI
      for (final inst in loan.installments!) {
        if (!inst.isPaid && inst.dueDate != null) {
          nextPaymentDate = inst.dueDate;
          break;
        }
      }

    } else {
      nextPaymentDate = loan.firstPaymentDate;
    }

    final bool isNextPaymentDue = _isPaymentDue(nextPaymentDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailsScreen(
                loan: loan
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: loanColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(loanIcon, color: loanColor, size: 16),
                  ),
                  const SizedBox(width: 6),

                  // TITLE & PRINCIPAL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.loanType,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: context.screenWidth * 0.04,
                          ),
                        ),
                        Text(
                          'Principal: ₹${loan.loanAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: context.screenWidth * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STATUS BADGE
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: loan.status == 'Active'
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      loan.status,
                      style: GoogleFonts.poppins(
                        fontSize: context.screenWidth * 0.025,
                        fontWeight: FontWeight.bold,
                        color: loan.status == 'Active'
                            ? Colors.green.shade800
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 25),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => _showLoanOptions(loan),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLoanDetail(
                    title: 'Monthly EMI',
                    value: _calculateEMI(loan),
                    color: Colors.blue,
                    showCheckmark: isCurrentMonthEmiPaid,
                  ),
                  _buildLoanDetail(
                    title: 'Next Payment',
                    value: _formatDate(nextPaymentDate),
                    color: isNextPaymentDue ? Colors.red : Colors.orange,
                    badge: isNextPaymentDue ? 'Due' : null,
                    badgeColor: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Loan Repayment Progress',
                style: GoogleFonts.poppins(
                    fontSize: context.screenWidth * 0.026, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loan.progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(loanColor),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(loan.progress * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: loanColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ₹${_calculateRemainingAmount(loan)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: context.screenWidth * 0.03,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoanDetailsScreen(
                                  loan: loan
                              ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: loanColor,
                      side: BorderSide(color: loanColor),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      minimumSize: const Size(70, 22),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: GoogleFonts.poppins(
                      fontSize: context.screenWidth * 0.026,),
                    ),
                    child: Text('View Details',
                      style: GoogleFonts.poppins()
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanDetail({
    required String title,
    required String value,
    required Color color,
    bool showCheckmark = false,
    String? badge,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: context.screenWidth * 0.026,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: context.screenWidth * 0.03,
              ),
            ),
            if (showCheckmark) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade700,
                  size: 10,
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor?.withAlpha(26) ?? Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: context.screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showLoanOptions(SingleLoan loan) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bool isActive = loan.status == 'Active';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Loan Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Mark Active / Inactive
              ListTile(
                leading: Icon(
                  isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: isActive ? Colors.orange : Colors.green,
                ),
                title: Text(isActive ? 'Mark as Inactive' : 'Mark as Active'),
                onTap: () async {
                  // Create updated loan model
                  loan.status = isActive ? 'Inactive' : 'Active';

                  final success = await  loanProvider.updateLoanModel(loan);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Loan marked as ${isActive ? 'inactive' : 'active'}'),
                        backgroundColor: isActive ? Colors.orange : Colors.green,
                      ),
                    );

                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to updating loan")),
                    );
                  }


                },
              ),

              // Edit
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title:  Text('Edit Loan' ,style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddLoanScreen(
                        isEditing: true,
                        loan: loan,
                      ),
                    ),
                  );
                },
              ),

              // Delete
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:  Text('Delete Loan',style: GoogleFonts.poppins(),),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(loan);
                },
              ),

              // Record Payment
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title:  Text('Record Payment',style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoanDetailsScreen(
                        loan: loan,
                        initialTab: 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _showDeleteConfirmation(SingleLoan loan) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Loan',style: GoogleFonts.poppins()),
          content: Text(
            'Are you sure you want to delete "${loan.loanType ?? 'Loan'}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final success = await  loanProvider.deleteLoanModel(loan.id);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loan deleted successfully',style: GoogleFonts.poppins()),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete loan")),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child:  Text('Delete',style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }


  // Check if payment is due (date has passed)
  bool _isPaymentDue(DateTime? paymentDate) {
    if (paymentDate == null) return false;
    final now = DateTime.now();
    return paymentDate.isBefore(now);
  }

  Color _getLoanColor(String loanType) {
    switch (loanType) {
      case 'Home Loan':
        return Colors.blue;
      case 'Car Loan':
        return Colors.green;
      case 'Personal Loan':
        return Colors.purple;
      case 'Education Loan':
        return Colors.orange;
      case 'Business Loan':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getLoanIcon(String loanType) {
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

  String _calculateEMI(SingleLoan loan) {
    double principal = loan.loanAmount;
    double rate = (loan.interestRate) / 100 / 12;   // monthly interest rate
    int time = loan.loanTerm;                       // number of months

    if (rate == 0 || time == 0) return '₹0';

    // EMI formula
    double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);

    return '₹${emi.toStringAsFixed(2)}';
  }


  String _calculateRemainingAmount(SingleLoan loan) {
    double principal = loan.loanAmount;
    double rate = (loan.interestRate) / 100 / 12; // monthly interest
    int time = loan.loanTerm;
    double progress = loan.progress; // already double in model

    if (rate == 0 || time == 0) {
      return '₹${principal.toStringAsFixed(2)}';
    }

    // EMI Formula
    double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);

    double totalAmount = emi * time;
    double remainingAmount = totalAmount * (1 - progress);

    return '₹${remainingAmount.toStringAsFixed(2)}';
  }


  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }



  Widget _buildLoanTypeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan Categories',
          style: GoogleFonts.poppins(
            fontSize: context.screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(label: 'All'),
              _buildFilterChip(label: 'Personal'),
              _buildFilterChip(label: 'Home'),
              _buildFilterChip(label: 'Car'),
              _buildFilterChip(label: 'Education'),
              _buildFilterChip(label: 'Business'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String label}) {
    final isSelected = _selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blue.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: context.screenWidth * 0.03,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/empty_loan_icon.svg'
          ),
          const SizedBox(height: 16),
          Text(
            'No loans found',
              style: GoogleFonts.poppins(
              fontSize: context.screenWidth * 0.05,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new loan to get started',
              style: GoogleFonts.poppins(
                fontSize: context.screenWidth * 0.04,
                color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLoanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text('Add Loan',style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  }
