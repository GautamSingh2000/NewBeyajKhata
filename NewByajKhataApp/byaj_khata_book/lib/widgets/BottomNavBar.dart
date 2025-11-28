import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: "assets/icons/selected_home.svg",
              label: "Home",
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: "assets/icons/selected_loan.svg",
              label: "Loans",
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: "assets/icons/interest_icon.svg",
              label: "Interest",
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: "assets/icons/selected_emi.svg",
              label: "EMI",
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: "assets/icons/selected_profile_icon.svg", // add icon
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required int index,
        required String icon,
        required String label,
      }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: 55,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? AppColors.blue0001 : AppColors.gray0001,
                BlendMode.srcIn,
              ),
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.blue0001 : AppColors.gray0001,
              ),
            ),
          ],
        ),
      ),
    );
  }
}











































// import 'package:byaj_khata_book/core/theme/AppColors.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
//
// import '../core/utils/HomeScreenEnum.dart';
// import '../providers/GlobalProvider.dart';
//
// class BottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const BottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GlobalProvider>(context);
//     if (!provider.isLoaded) {
//       Future.microtask(() => provider.loadPreferences());
//     }
//     final navItems = provider.selectedNavItems;
//
//     return SafeArea(
//       bottom: true,
//       child: Container(
//         height: 60, // Reduced from 70 to better fit with gesture navigation
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               spreadRadius: 0,
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             // Home button (index 0)
//             _buildNavItem(
//               context,
//               0,
//               navItems[0].selectedIcon,
//               navItems[0].title,
//             ),
//
//             // First customizable button (index 1)
//             if (navItems.length > 1)
//               _buildNavItem(
//                 context,
//                 1,
//                 navItems[1].selectedIcon,
//                 navItems[1].title,
//               ),
//
//             // Center tools button (index 2)
//             _buildToolsButton(context),
//
//             // Second customizable button (index 3)
//             if (navItems.length > 2)
//               _buildNavItem(
//                 context,
//                 3,
//                 navItems[2].selectedIcon,
//                 navItems[2].title,
//               ),
//
//             // Third customizable button (index 4) - replaces Manage button
//             if (navItems.length > 3)
//               _buildNavItem(
//                 context,
//                 4,
//                 navItems[3].selectedIcon,
//                 navItems[3].title,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(
//     BuildContext context,
//     int index,
//     String selectedIcon,
//     String label,
//   ) {
//     final isSelected = currentIndex == index;
//
//     return InkWell(
//       onTap: () {
//         _onItemTapped(index, label);
//       },
//       child: Container(
//         width: 55,
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SvgPicture.asset(
//                selectedIcon,
//               width: 24,
//               height: 24,
//               colorFilter: ColorFilter.mode(
//                 isSelected ? AppColors.blue0001 : AppColors.gray0001,
//                 BlendMode.srcIn,
//               ),
//               fit: BoxFit.contain,
//             ),
//             const SizedBox(height: 3),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 11,
//                 fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
//                 color: isSelected ? AppColors.blue0001 : AppColors.gray0001,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolsButton(BuildContext context) {
//     return GestureDetector(
//       onTap: () => _showToolsPopup(context),
//       child: Container(
//         width: 55,
//         height: 55,
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           gradient: AppColors.lightBlueGradient,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.blue.shade300.withOpacity(0.5),
//               spreadRadius: 1,
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: const Icon(
//           Icons.grid_view_rounded,
//           color: Colors.white,
//           size: 28,
//         ),
//       ),
//     );
//   }
//
//   void _showToolsPopup(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => ToolsPopup(),
//     );
//   }
//
//   void _onItemTapped(int index, String label) {
//     onTap(index);
//   }
// }
//
// class ToolsPopup extends StatelessWidget {
//   ToolsPopup({Key? key}) : super(key: key);
//
//   // Group tools by category
//   final Map<String, List<Map<String, dynamic>>> _toolCategories = {
//     'Calculators': [
//       {
//         'icon': "assets/icons/selected_emi.svg",
//         'title': BottomBarItems.emiCalc.title,
//         'id': BottomBarItems.emiCalc.id,
//         'color': Colors.purple,
//       },
//       {
//         'icon': "assets/icons/selected_sip.svg",
//         'color': Colors.indigo,
//         'title': BottomBarItems.sipCalc.title,
//         'id': BottomBarItems.sipCalc.id,
//       },
//       {
//         'icon': "assets/icons/selected_tax.svg",
//         'title': BottomBarItems.taxCalc.title,
//         'id': BottomBarItems.taxCalc.id,
//         'color': Colors.red,
//       },
//     ],
//     'Diaries': [
//       {
//         'icon': "assets/icons/selected_bill.svg",
//         'title': BottomBarItems.billDiary.title,
//         'id': BottomBarItems.billDiary.id,
//         'color': Colors.blue.shade700,
//       },
//       {
//         'icon': "assets/icons/selected_milk.svg",
//         'color': Colors.amber.shade700,
//         'title': BottomBarItems.milkDiary.title,
//         'id': BottomBarItems.milkDiary.id,
//       },
//       {
//         'icon': "assets/icons/selected_work.svg",
//         'color': Colors.blue,
//         'title': BottomBarItems.workDiary.title,
//         'id': BottomBarItems.workDiary.id,
//       },
//     ],
//     'Other': [
//       {
//         'icon': "assets/icons/selected_loan.svg",
//         'color': Colors.blue,
//         'title': BottomBarItems.loans.title,
//         'id': BottomBarItems.loans.id,
//       },
//       {
//         'icon': "assets/icons/selected_credit_card.svg",
//         'color': Colors.indigo,
//         'title': BottomBarItems.cards.title,
//         'id': BottomBarItems.cards.id,
//       },
//     ],
//   };
//
//   @override
//   Widget build(BuildContext context) {
//     // Get the currently selected nav items to filter them out from the tools popup
//     final navPrefs = Provider.of<GlobalProvider>(context, listen: false);
//     // Create a list of IDs that are already in the bottom nav
//     final selectedNavItemIds = navPrefs.selectedNavItems
//         .map((item) => item.id)
//         .toList();
//
//     // Flatten all tools into a single list and filter out those in navigation
//     List<Map<String, dynamic>> availableTools = [];
//     for (var category in _toolCategories.keys) {
//       final tools = _toolCategories[category]!;
//       availableTools.addAll(
//         tools.where((tool) => !selectedNavItemIds.contains(tool['id'])),
//       );
//     }
//
//     // Sort tools alphabetically by title
//     availableTools.sort(
//       (a, b) => a['title'].toString().compareTo(b['title'].toString()),
//     );
//
//     return Container(
//       padding: const EdgeInsets.only(top: 24, bottom: 24),
//       height: MediaQuery.of(context).size.height * 0.7,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             spreadRadius: 0,
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 50,
//             height: 5,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'More Tools',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Text(
//               'Access additional tools not in your bottom navigation',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: availableTools.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.check_circle_outline,
//                           size: 64,
//                           color: Colors.grey.shade400,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'All tools are in your navigation bar',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'You can customize your navigation in Settings',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : GridView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 3,
//                           childAspectRatio: 0.9,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 16,
//                         ),
//                     itemCount: availableTools.length,
//                     itemBuilder: (context, index) {
//                       final tool = availableTools[index];
//                       return _buildToolItem(
//                         context,
//                         icon: tool['icon'],
//                         title: tool['title'],
//                         color: tool['color'],
//                         id: tool['id'],
//                       );
//                     },
//                   ),
//           ),
//
//           // Add button to manage navigation
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Navigator.push(
//                 //     context,
//                 //     MaterialPageRoute(
//                 //         // builder: (context) => const NavSettingsScreen())
//                 // );
//               },
//               icon: const Icon(Icons.tune),
//               label: const Text('Customize Navigation'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.blue0001,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 48),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildToolItem(
//     BuildContext context, {
//     required String icon,
//     required String title,
//     required Color color,
//     required String id,
//   }) {
//     return InkWell(
//       onTap: () {
//         Navigator.pop(context);
//         // _navigateToTool(context, id);
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.1),
//               spreadRadius: 0,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: SvgPicture.asset(
//                 icon,
//                 width: 28,
//                 height: 28,
//                 fit: BoxFit.contain,
//                 colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
