import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/AppColors.dart';

class IntererestCalculatorScreen extends StatefulWidget {
  const IntererestCalculatorScreen({super.key});

  @override
  State<IntererestCalculatorScreen> createState() =>
      _IntererestCalculatorScreenState();
}

class _IntererestCalculatorScreenState
    extends State<IntererestCalculatorScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController durationCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String rotation = "No Rotation";

  String mode = "date"; // <-- IMPORTANT (date or duration)

  String resultPrincipal = "--";
  String resultInterest = "--";
  String resultTotal = "--";

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue.shade50.withOpacity(0.5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.05,
            vertical: w * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: w * 0.04),

              _textField(
                controller: amountCtrl,
                title: "Amount",
                hint: "Enter amount",
                width: w,
              ),

              SizedBox(height: w * 0.04),

              _textField(
                controller: rateCtrl,
                title: "Interest rate",
                hint: "% / Month",
                width: w,
              ),

              SizedBox(height: w * 0.04),

              _dropDown(
                title: "Rotation Type",
                selected: rotation,
                items: const ["No Rotation", "Monthly Rotation", "Yearly Rotation"],
                onChanged: (value) => setState(() => rotation = value!),
                width: w,
              ),

              SizedBox(height: w * 0.02),

              Row(
                children: [
                  SvgPicture.asset(
                    "assets/icons/info.svg",
                    width: w * 0.05,
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    "Principle amount stays the same",
                    style: GoogleFonts.poppins(
                      fontSize: w * 0.03,
                      color: Colors.black45,
                    ),
                  )
                ],
              ),

              SizedBox(height: w * 0.06),

              _segmentedButton(w),

              SizedBox(height: w * 0.05),

              mode == "date" ? _dateInputs(w) : _durationInput(w),

              SizedBox(height: w * 0.08),

              _calculateButton(w),

              SizedBox(height: w * 0.04),

              _resetButton(w),

              SizedBox(height: w * 0.08),

              _resultCard(w),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- UI ELEMENTS ------------------------

  Widget _textField({
    required TextEditingController controller,
    required String title,
    required String hint,
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: width * 0.035,
              fontWeight: FontWeight.w500,
            )),
        SizedBox(height: width * 0.02),
        Container(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.02),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: width * 0.035),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  // DROPDOWN
  Widget _dropDown({
    required String title,
    required String selected,
    required List<String> items,
    required Function(String?) onChanged,
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: width * 0.03,
              fontWeight: FontWeight.w500,
            )),
        SizedBox(height: width * 0.02),
        Container(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.02),
          ),
          child: DropdownButtonFormField(
            value: selected,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  // SEGMENT SWITCH
  Widget _segmentedButton(double w) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => mode = "date"),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: w * 0.03),
                decoration: BoxDecoration(
                  color: mode == "date"
                      ? AppColors.primaryColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                alignment: Alignment.center,
                child: Text(
                  "By Date Range",
                  style: GoogleFonts.poppins(
                    fontSize: w * 0.03,
                    color: mode == "date" ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => mode = "duration"),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: w * 0.03),
                alignment: Alignment.center,
                child: Text(
                  "By Duration",
                  style: GoogleFonts.poppins(
                    fontSize: w * 0.03,
                    color: mode == "duration" ? AppColors.primaryColor : Colors.black54,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // DATE RANGE INPUT
  Widget _dateInputs(double w) {
    return Row(
      children: [
        Expanded(
          child: _datePicker(
            context: context,
            label: "From",
            date: startDate,
            width: w,
            onTap: () async {
              final picked = await _pickDate(context);
              if (picked != null) setState(() => startDate = picked);
            },
          ),
        ),
        SizedBox(width: w * 0.04),
        Expanded(
          child: _datePicker(
            context: context,
            label: "To",
            date: endDate,
            width: w,
            onTap: () async {
              final picked = await _pickDate(context);
              if (picked != null) setState(() => endDate = picked);
            },
          ),
        ),
      ],
    );
  }

  // DURATION INPUT
  Widget _durationInput(double w) {
    return _textField(
      controller: durationCtrl,
      title: "Duration (Months)",
      hint: "Enter months",
      width: w,
    );
  }

  // DATE PICKER
  Widget _datePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required double width,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.035,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.02),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? label
                  : "${date.day}/${date.month}/${date.year}",
              style: GoogleFonts.poppins(fontSize: width * 0.035),
            ),
            SvgPicture.asset(
              "assets/icons/calendar.svg",
              width: width * 0.05,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // CALCULATE BUTTON
  Widget _calculateButton(double w) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
        ),
        onPressed: calculateInterest,
        child: Text(
          "Calculate",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // RESET BUTTON
  Widget _resetButton(double w) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            amountCtrl.clear();
            rateCtrl.clear();
            durationCtrl.clear();
            startDate = null;
            endDate = null;
            resultPrincipal = resultInterest = resultTotal = "--";
          });
        },
        child: Text(
          "Reset Calculation",
          style: GoogleFonts.poppins(
            color: AppColors.blue0003,
            fontSize: w * 0.035,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // RESULT CARD
  Widget _resultCard(double w) {
    return Container(
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          _resultRow("Principle Amount", resultPrincipal, w),
          SizedBox(height: w * 0.03),
          _resultRow("Interest Amount", resultInterest, w),
          SizedBox(height: w * 0.03),
          _resultRow("Total", resultTotal, w),
        ],
      ),
    );
  }

  Widget _resultRow(String title, String value, double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
            )),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  // ------------------ LOGIC ----------------------

  void calculateInterest() {
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;

    if (amount == 0 || rate == 0) return;

    int months = 0;

    if (mode == "date") {
      if (startDate == null || endDate == null) return;

      months = (endDate!.difference(startDate!).inDays / 30).round();
    } else {
      months = int.tryParse(durationCtrl.text) ?? 0;
    }

    double interest = amount * rate * months / 100;

    if (rotation == "Yearly Rotation") {
      interest *= 12;
    }

    setState(() {
      resultPrincipal = amount.toStringAsFixed(2);
      resultInterest = interest.toStringAsFixed(2);
      resultTotal = (amount + interest).toStringAsFixed(2);
    });
  }

  Future<DateTime?> _pickDate(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
  }
}
