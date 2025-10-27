// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../core/constants/SharedPreferenceKeys.dart';
// import '../core/di/ServiceLocator.dart';
// import '../core/utils/HomeScreenEnum.dart';
//
// class NavItem {
//   final String id;
//   final String title;
//   final String selectedIcon; // svg path for selected state
//   final String unselectedIcon; // svg path for unselected state
//   final bool isFixed;
//
//   NavItem({
//     required this.id,
//     required this.title,
//     required this.selectedIcon,
//     required this.unselectedIcon,
//     this.isFixed = false,
//   });
// }
//
// class BottomNavigationProvider with ChangeNotifier {
//   final List<NavItem> _availableItemsForBottomBar = [
//     NavItem(
//       id: BottomBarItems.home.id,
//       title: BottomBarItems.home.title,
//       selectedIcon: "assets/icons/selected_home.svg",
//       unselectedIcon: "assets/icons/unselected_home.svg",
//       isFixed: true,
//     ),
//     NavItem(
//       id: BottomBarItems.loans.id,
//       title: BottomBarItems.loans.title,
//       selectedIcon: "assets/icons/selected_loan.svg",
//       unselectedIcon: "assets/icons/unselected_loan.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.cards.id,
//       title: BottomBarItems.cards.title,
//       selectedIcon: "assets/icons/selected_credit_card.svg",
//       unselectedIcon: "assets/icons/unselected_credit_card.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.billDiary.id,
//       title: BottomBarItems.billDiary.title,
//       selectedIcon: "assets/icons/selected_bill.svg",
//       unselectedIcon: "assets/icons/unselected_bill.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.emiCalc.id,
//       title: BottomBarItems.emiCalc.title,
//       selectedIcon: "assets/icons/selected_emi.svg",
//       unselectedIcon: "assets/icons/unselected_emi.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.sipCalc.id,
//       title: BottomBarItems.sipCalc.title,
//       selectedIcon: "assets/icons/selected_sip.svg",
//       unselectedIcon: "assets/icons/unselected_sip.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.taxCalc.id,
//       title: BottomBarItems.taxCalc.title,
//       selectedIcon: "assets/icons/selected_tax.svg",
//       unselectedIcon: "assets/icons/unselected_tax.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.milkDiary.id,
//       title: BottomBarItems.milkDiary.title,
//       selectedIcon: "assets/icons/selected_milk.svg",
//       unselectedIcon: "assets/icons/unselected_milk.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.workDiary.id,
//       title: BottomBarItems.workDiary.title,
//       selectedIcon: "assets/icons/selected_work.svg",
//       unselectedIcon: "assets/icons/unselected_work.svg",
//     ),
//     NavItem(
//       id: BottomBarItems.teaDiary.id,
//       title: BottomBarItems.teaDiary.title,
//       selectedIcon: "assets/icons/selected_tea.svg",
//       unselectedIcon: "assets/icons/unselected_tea.svg",
//     ),
//   ];
//
//   String _currentNavId = BottomBarItems.home.id;
//
//   // Default nav items
//   List<String> _defaultBottomBarItems = [
//     BottomBarItems.home.id,
//     BottomBarItems.loans.id,
//     BottomBarItems.cards.id,
//     BottomBarItems.billDiary.id,
//   ];
//
//   List<NavItem> get availableNavItems => _availableItemsForBottomBar;
//
//   List<NavItem> get selectedNavItems => _defaultBottomBarItems
//       .map(
//         (id) => _availableItemsForBottomBar.firstWhere((item) => item.id == id),
//       )
//       .toList();
//
//   String get currentNavId => _currentNavId;
//
//   void onItemSelected(int index, BuildContext context) {
//     _currentNavId = selectedNavItems[index].id;
//     notifyListeners();
//
//     // here you can do go_router navigation
//     // context.go("/${_currentNavId}");
//   }
//
//   void setCurrentNav(String id) {
//     _currentNavId = id;
//     notifyListeners();
//   }
//
//   void toggleSelection(String id) {
//     if (id == BottomBarItems.home) return; // can't remove home
//     if (_defaultBottomBarItems.contains(id)) {
//       if (_defaultBottomBarItems.length > 2) {
//         _defaultBottomBarItems.remove(id);
//       }
//     } else {
//       if (_defaultBottomBarItems.length < 4) {
//         _defaultBottomBarItems.add(id);
//       }
//     }
//     notifyListeners();
//   }
//
//   final prefs = locator<SharedPreferences>();
//   bool _isLoaded = false;
//
//   // Public getters
//   bool get isLoaded => _isLoaded;
//
//   // Return only available items that are not fixed
//   // List<NavItem> get availableNavItems {
//   //   return _availableItemsForBottomBar.where((item) => !item.isFixed).toList();
//   // }
//
//   // Return all available items including fixed ones
//   List<NavItem> get allNavItems => _availableItemsForBottomBar;
//
//   // List<NavItem> get selectedNavItems {
//   //   // Always include fixed items and then the selected ones
//   //   List<NavItem> fixedItems = _availableItemsForBottomBar.where((item) => item.isFixed).toList();
//   //
//   //   List<NavItem> selectedItems = _defaultBottomBarItems
//   //       .where((id) => !fixedItems.any((item) => item.id == id)) // Don't duplicate fixed items
//   //       .map((id) => _availableItemsForBottomBar.firstWhere(
//   //           (item) => item.id == id,
//   //       orElse: () => _availableItemsForBottomBar.firstWhere((item) => !item.isFixed)))
//   //       .toList();
//   //
//   //   return [...fixedItems, ...selectedItems];
//   // }
//
//   bool isSelected(String id) {
//     // A fixed item is always "selected"
//     final navItem = _availableItemsForBottomBar.firstWhere(
//       (item) => item.id == id,
//       orElse: () => NavItem(
//         id: '',
//         title: '',
//         unselectedIcon: "assets/icons/error.svg",
//         selectedIcon: "assets/icons/error.svg",
//       ),
//     );
//
//     if (navItem.isFixed) {
//       return true;
//     }
//
//     return _defaultBottomBarItems.contains(id);
//   }
//
//   Future<void> loadPreferences() async {
//     if (_isLoaded) return;
//
//     try {
//       final savedNavItems = prefs.getStringList(
//         SharedPreferenceKeys.SELECTED_BOTTOM_NAV_ITEMS,
//       );
//
//       if (savedNavItems != null && savedNavItems.isNotEmpty) {
//         // Always ensure fixed items like 'home' are included
//         final fixedItemIds = _availableItemsForBottomBar
//             .where((item) => item.isFixed)
//             .map((item) => item.id)
//             .toList();
//
//         _defaultBottomBarItems = [
//           ...fixedItemIds,
//           ...savedNavItems.where((id) => !fixedItemIds.contains(id)),
//         ];
//       }
//
//       _isLoaded = true;
//       notifyListeners();
//     } catch (e) {
//       // Removed debug print
//     }
//   }
//
//   Future<void> savePreferences() async {
//     try {
//       await prefs.setStringList(
//         SharedPreferenceKeys.SELECTED_BOTTOM_NAV_ITEMS,
//         _defaultBottomBarItems,
//       );
//     } catch (e) {
//       // Removed debug print
//     }
//   }
//
//   Future<void> toggleNavItem(String id) async {
//     // Don't allow toggling fixed items
//     final navItem = _availableItemsForBottomBar.firstWhere(
//       (item) => item.id == id,
//       orElse: () => NavItem(
//         id: '',
//         title: '',
//         selectedIcon: "assets/icons/error.svg",
//         unselectedIcon: "assets/icons/error.svg",
//       ),
//     );
//
//     if (navItem.isFixed) {
//       return;
//     }
//
//     if (_defaultBottomBarItems.contains(id)) {
//       // Don't allow removing the last item
//       if (_defaultBottomBarItems.length > 1) {
//         _defaultBottomBarItems.remove(id);
//       }
//     } else {
//       // Maximum 4 items in the nav bar (including fixed items and tools button)
//       if (_defaultBottomBarItems.length < 4) {
//         _defaultBottomBarItems.add(id);
//       }
//     }
//
//     await savePreferences();
//     notifyListeners();
//   }
//
//   Future<void> resetToDefaults() async {
//     // Make sure to include fixed items
//     final fixedItemIds = _availableItemsForBottomBar
//         .where((item) => item.isFixed)
//         .map((item) => item.id)
//         .toList();
//
//     _defaultBottomBarItems = [
//       ...fixedItemIds,
//       BottomBarItems.loans.id,
//       BottomBarItems.cards.id,
//       BottomBarItems.billDiary.id,
//     ];
//
//     // Ensure we don't exceed 4 items total (including tools button)
//     if (_defaultBottomBarItems.length > 4) {
//       _defaultBottomBarItems = _defaultBottomBarItems.sublist(0, 4);
//     }
//
//     await savePreferences();
//     notifyListeners();
//   }
// }
