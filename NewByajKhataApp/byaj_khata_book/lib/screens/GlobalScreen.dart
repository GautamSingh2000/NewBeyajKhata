import 'package:byaj_khata_book/screens/Home/HomeScreen.dart';
import 'package:byaj_khata_book/widgets/TopAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/RouteNames.dart';
import '../core/utils/HomeScreenEnum.dart';
import '../providers/GlobalProvider.dart';
import '../widgets/BottomNavBar.dart';
import '../widgets/NotificationBadge.dart';
import 'BillDiaryScreen.dart';
import 'CardScreen.dart';
import 'EmiCalculatorScreen.dart';
import 'LoanScreen.dart';
import 'MilkDiaryScreen.dart';
import 'MoreToolsScreen.dart';
import 'SipCalculatorScreen.dart';
import 'TaxCalculatorScreen.dart';
import 'WorkDiaryScreen.dart';

class GlobalScreen extends StatefulWidget {
  final Widget child;
  const GlobalScreen({super.key, required this.child});

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GlobalProvider>(context);

    final Map<String, Widget> screenMap = {
      BottomBarItems.home.id : const HomeScreen(),
      BottomBarItems.loans.id: const LoanScreen(),
      BottomBarItems.cards.id : const CardScreen(),
      BottomBarItems.billDiary.id: const BillDiaryScreen(),
      BottomBarItems.milkDiary.id: const MilkDiaryScreen(),
      BottomBarItems.workDiary.id: const WorkDiaryScreen(),
      BottomBarItems.tools.id: const MoreToolsScreen(),
      BottomBarItems.emiCalc.id: const EmiCalculatorScreen(),
      BottomBarItems.sipCalc.id: const SipCalculatorScreen(),
      BottomBarItems.taxCalc.id: const TaxCalculatorScreen(),
    };

    final List<Widget> selectedScreens = provider.selectedNavItems
        .map((item) => screenMap[item.id] ?? const HomeScreen())
        .toList();

    // Ensure we have at least one screen
    if (selectedScreens.isEmpty) {
      selectedScreens.add(const HomeScreen());
    }
    final String currentTitle =
        provider.selectedNavItems[_currentIndex].title;


    return Scaffold(
      body: widget.child,
      appBar: TopAppBar(
        title: currentTitle,
        showBackButton: false,
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: SvgPicture.asset(
              "assets/icons/history_icon.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              fit: BoxFit.contain,
            ),
            tooltip: 'Transaction History',
            onPressed: () {
             context.go(RouteNames.contactHistory);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Make sure we don't exceed the available screens
          if (index == 2) {
            // Center button for tools
            setState(() {
              _currentIndex = index;
            });
          } else if (index == 3 || index == 4) {
            // We need to handle positions 3 and 4 specially
            final adjustedIndex = index - 1; // Adjust for the center button
            if (adjustedIndex - 1 < selectedScreens.length) { // -1 because we're 0-indexed
              setState(() {
                _currentIndex = index;
              });
            }
          } else if (index < selectedScreens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

}
