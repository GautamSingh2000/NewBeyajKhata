import 'package:byaj_khata_book/screens/Home/HomeScreen.dart';
import 'package:byaj_khata_book/widgets/TopAppBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/GlobalProvider.dart';
import '../core/utils/HomeScreenEnum.dart';
import '../widgets/BottomNavBar.dart';
import 'Emi/EmiCalculatorScreen.dart';
import 'loan/LoanScreen.dart';
import 'ProfileScreen.dart';

class GlobalScreen extends StatefulWidget {
  const GlobalScreen({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    LoanScreen(),
    EmiCalculatorScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GlobalProvider>(context);

    final List<String> titles = [
      "Home",
      "Loans",
      "EMI Calculator",
      "Profile",
    ];

    return Scaffold(
      appBar: TopAppBar(
        title: titles[provider.currentIndex],
        showBackButton: false,
      ),

      body: _screens[provider.currentIndex],

      /// 🔥 CUSTOM BOTTOM NAV BAR (Your Version)
      bottomNavigationBar: BottomNavBar(
        currentIndex: provider.currentIndex,
        onTap: (index) {
          provider.setCurrentIndex(index);
        },
      ),
    );
  }
}
