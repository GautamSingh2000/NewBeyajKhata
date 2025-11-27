import 'package:byaj_khata_book/providers/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../data/models/Installment.dart';
import '../data/models/LoanSummary.dart';
import '../data/models/SingleLoan.dart';

class LoanProvider with ChangeNotifier {
  // Hive Boxes
  late Box<SingleLoan> _activeLoanBox;
  late Box<SingleLoan> _completedLoanBox;

  List<SingleLoan> _activeLoans = [];
  List<SingleLoan> _completedLoans = [];
  bool _isLoading = false;

  String _selectedCategory = 'All';

  Logger logger = new Logger();

  void loadLoans() {
    _loadHiveBoxes();
  }

  String get interestViewMode => _selectedCategory;
  List<SingleLoan> get activeLoans => _activeLoans;
  bool get isLoading => _isLoading;

  SingleLoan? getLoanById(String id) {
    try {
      // Check in active loans
      final activeLoan = _activeLoans.firstWhere(
            (loan) => loan.id == id,
        orElse: () => null as SingleLoan,
      );

      if (activeLoan != null) return activeLoan;

      final completedLoan = _completedLoans.firstWhere(
            (loan) => loan.id == id,
        orElse: () => null as SingleLoan,
      );

      return completedLoan;
    } catch (e) {
      debugPrint("❌ getLoanById($id) failed: $e");
      return null;
    }
  }



  Future<void> _loadHiveBoxes() async {
    _isLoading = true;
    notifyListeners();

    _activeLoanBox = Hive.box<SingleLoan>('loans');
    _completedLoanBox = Hive.box<SingleLoan>('completedLoans');

    _activeLoans = _activeLoanBox.values.toList();
    _completedLoans = _completedLoanBox.values.toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addLoanModel(SingleLoan loan) async {
    try {
      logger.e("➕ Adding Loan ID: ${loan.id}");

      await _activeLoanBox.put(loan.id, loan);

      logger.e("📦 Hive Keys After Add: ${_activeLoanBox.keys.toList()}");

      _activeLoans = _activeLoanBox.values.toList();
      notifyListeners();
      return true; // SUCCESS
    } catch (e) {
      logger.e("❌ Error Adding Loan: $e");
      return false; // FAILED
    }
  }

  Future<bool> deleteLoanModel(String id) async {
    try {
    logger.e("🗑 Attempting to delete loan with ID: $id");

    // Print Hive keys before delete
    logger.e("📦 Hive Keys Before Delete: ${_activeLoanBox.keys.toList()}");

    // Print Hive values before delete
    logger.e("📦 Hive Values Before Delete:");
    _activeLoanBox.values.forEach((l) {
      logger.e(" - ID: ${l.id}, Type: ${l.loanType}, Amount: ${l.loanAmount}");
    });

    // Try delete
    await _activeLoanBox.delete(id);

    logger.e("❗ Deleted Loan ID: $id");

    // Print after delete
    logger.e("📦 Hive Keys After Delete: ${_activeLoanBox.keys.toList()}");

    logger.e("📦 Hive Values After Delete:");
    _activeLoanBox.values.forEach((l) {
      logger.e(" - ID: ${l.id}, Type: ${l.loanType}, Amount: ${l.loanAmount}");
    });

    _activeLoans = _activeLoanBox.values.toList();
    notifyListeners();
    return true; // SUCCESS
    } catch (e) {
      logger.e("❌ Error deleting loan: $e");
      return false; // FAILED
    }
  }

  Future<bool> updateLoanModel(SingleLoan loan) async {
    try {
    logger.e("✏ Updating Loan ID: ${loan.id}");

    await _activeLoanBox.put(loan.id, loan);

    logger.e("📦 Hive Keys After Update: ${_activeLoanBox.keys.toList()}");

    logger.e("📦 Hive Values After Update:");
    _activeLoanBox.values.forEach((l) {
      logger.e(" - ID: ${l.id}, Type: ${l.loanType}, Amount: ${l.loanAmount}");
    });

    _activeLoans = _activeLoanBox.values.toList();
    notifyListeners();
    return true; // SUCCESS
    } catch (e) {
      logger.e("❌ Error updating loan: $e");
      return false; // FAILED
    }
  }

  LoanSummary getCategorySummary(UserProvider userProvider) {
    List<SingleLoan> filteredLoans;

    if (_selectedCategory == "All") {
      filteredLoans = _activeLoans;
    } else {
      filteredLoans = _activeLoans.where((loan) =>
      loan.category == _selectedCategory ||
          loan.loanType == "${_selectedCategory} Loan"
      ).toList();
    }

    double totalAmount = 0.0;
    double dueAmount = 0.0;

    for (var loan in filteredLoans) {
      totalAmount += loan.loanAmount;

      // EMI Calculation
      double P = loan.loanAmount;
      double R = loan.interestRate / 100 / 12;
      int N = loan.loanTerm;

      if (R > 0 && N > 0) {
        double emi = P * R * _pow(1 + R, N) / (_pow(1 + R, N) - 1);
        dueAmount += emi;
      }
    }

    return  LoanSummary(
      userName: userProvider.user?.name ?? "User",
      activeLoans: filteredLoans.length,
      totalAmount: totalAmount,
      dueAmount: dueAmount,
    );
  }

  // ---------------------------
  // 🔹 OVERALL SUMMARY (MODEL VERSION)
  // ---------------------------
  LoanSummary getLoanSummary(UserProvider userProvider) {
    final List<SingleLoan> activeLoans =
    _activeLoans.where((loan) => loan.status != "Inactive").toList();

    int totalActiveLoans = activeLoans.length;
    double totalAmount = 0.0;
    double dueAmount = 0.0;

    DateTime now = DateTime.now();

    for (var loan in activeLoans) {
      totalAmount += loan.loanAmount;

      bool emiBilledThisMonth = false;

      // Check Installments
      if (loan.installments != null) {
        for (Installment inst in loan.installments!) {
          if (inst.dueDate != null &&
              inst.dueDate!.month == now.month &&
              inst.dueDate!.year == now.year) {
            if (!inst.isPaid) {
              dueAmount += inst.totalAmount;
            }
            emiBilledThisMonth = true;
            break;
          }
        }
      }

      // If no installment found, compute EMI manually
      if (!emiBilledThisMonth) {
        double P = loan.loanAmount;
        double R = loan.interestRate / 100 / 12;
        int N = loan.loanTerm;

        if (R > 0 && N > 0) {
          double emi = P * R * _pow(1 + R, N) / (_pow(1 + R, N) - 1);
          dueAmount += emi;
        }
      }
    }

    String userName = userProvider?.user?.name ?? "User";

    return  LoanSummary(
      userName: userName,
      activeLoans: totalActiveLoans,
      totalAmount: totalAmount,
      dueAmount: dueAmount,
    );
  }

  double _pow(double x, int n) {
    double result = 1;
    for (int i = 0; i < n; i++) result *= x;
    return result;
  }
}
