// import 'package:byaj_khata_book/screens/Home/HomeScreen.dart';
// import 'package:byaj_khata_book/widgets/TopAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import '../core/constants/RouteNames.dart';
// import '../core/utils/HomeScreenEnum.dart';
// import '../providers/GlobalProvider.dart';
// import '../widgets/BottomNavBar.dart';
// import '../widgets/NotificationBadge.dart';
// import 'BillDiaryScreen.dart';
// import 'CardScreen.dart';
// import 'Emi/EmiCalculatorScreen.dart';
// import 'loan/LoanScreen.dart';
// import 'MilkDiaryScreen.dart';
// import 'MoreToolsScreen.dart';
// import 'SipCalculatorScreen.dart';
// import 'TaxCalculatorScreen.dart';
// import 'WorkDiaryScreen.dart';
//
// class GlobalScreenOld extends StatefulWidget {
//   final Widget child;
//   const GlobalScreenOld({super.key, required this.child});
//
//   @override
//   State<GlobalScreenOld> createState() => _GlobalScreenOldState();
// }
//
// class _GlobalScreenOldState extends State<GlobalScreenOld> {
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GlobalProvider>(context);
//
//     final Map<String, Widget> screenMap = {
//       BottomBarItems.home.id : const HomeScreen(),
//       BottomBarItems.loans.id: const LoanScreen(),
//       BottomBarItems.emiCalc.id: const EmiCalculatorScreen(),
//       BottomBarItems.cards.id : const CardScreen(),
//       BottomBarItems.billDiary.id: const BillDiaryScreen(),
//       BottomBarItems.milkDiary.id: const MilkDiaryScreen(),
//       BottomBarItems.workDiary.id: const WorkDiaryScreen(),
//       BottomBarItems.tools.id: const MoreToolsScreen(),
//       BottomBarItems.sipCalc.id: const SipCalculatorScreen(),
//       BottomBarItems.taxCalc.id: const TaxCalculatorScreen(),
//     };
//
//     final List<Widget> selectedScreens = provider.selectedNavItems
//         .map((item) => screenMap[item.id] ?? const HomeScreen())
//         .toList();
//
//     // Ensure we have at least one screen
//     if (selectedScreens.isEmpty) {
//       selectedScreens.add(const HomeScreen());
//     }
//     final String currentTitle =
//         provider.selectedNavItems[_currentIndex].title;
//
//
//     return Scaffold(
//       body: selectedScreens[_currentIndex],
//       appBar: TopAppBar(
//         title: currentTitle,
//         showBackButton: false,
//
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           // Make sure we don't exceed the available screens
//           if (index == 2) {
//             // Center button for tools
//             setState(() {
//               _currentIndex = provider.selectedNavItems.length; // or a fixed tools index
//             });
//           } else if (index == 3 || index == 4) {
//             // We need to handle positions 3 and 4 specially
//             final adjustedIndex = index - 1; // Adjust for the center button
//             if (adjustedIndex - 1 < selectedScreens.length) { // -1 because we're 0-indexed
//               setState(() {
//                 _currentIndex = index;
//               });
//             }
//           } else if (index < selectedScreens.length) {
//             setState(() {
//               _currentIndex = index;
//             });
//           }
//         },
//       ),
//     );
//   }
//
// }
