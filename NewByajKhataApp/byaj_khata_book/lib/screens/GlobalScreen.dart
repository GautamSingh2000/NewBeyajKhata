import 'dart:io';

import 'package:byaj_khata_book/screens/Home/HomeScreen.dart';
import 'package:byaj_khata_book/widgets/TopAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../core/theme/AppColors.dart';
import '../data/models/User.dart';
import '../providers/GlobalProvider.dart';
import '../providers/UserProvider.dart';         // ⭐ IMPORTANT
import '../widgets/BottomNavBar.dart';
import 'Emi/EmiCalculatorScreen.dart';
import 'IntererestCalculatorScreen.dart';
import 'loan/LoanScreen.dart';
import 'ProfileScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalScreen extends StatefulWidget {
  const GlobalScreen({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    HomeScreen(),
    LoanScreen(),
    IntererestCalculatorScreen(),
    EmiCalculatorScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final global = Provider.of<GlobalProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final List<String> titles = [
      "Home",
      "Loans",
      "Interest Calculator",
      "EMI Calculator",
      "Profile",
    ];

    return Scaffold(
      key: _scaffoldKey,

      drawer: _buildDrawer(context, global, userProvider),

      appBar: TopAppBar(
        title: titles[global.currentIndex],
        showBackButton: false,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),

      body: _screens[global.currentIndex],

      bottomNavigationBar: BottomNavBar(
        currentIndex: global.currentIndex,
        onTap: (index) {
          global.setCurrentIndex(index);
        },
      ),
    );
  }

  // ---------------- DRAWER ------------------------

  Widget _buildDrawer(
      BuildContext context, GlobalProvider global, UserProvider userProvider) {
    final user = userProvider.user; // ⭐ The actual logged-in user

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _drawerHeader(global, user),

          _drawerItem(
            title: "Home",
            icon: "assets/icons/selected_home.svg",
            index: 0,
            global: global,
          ),
          _drawerItem(
            title: "Loans",
            icon:"assets/icons/selected_loan.svg",
            index: 1,
            global: global,
          ),
          _drawerItem(
            title: "Interest Calculator",
            icon: "assets/icons/interest_icon.svg",
            index: 2,
            global: global,
          ),
          _drawerItem(
            title: "EMI Calculator",
            icon: "assets/icons/selected_emi.svg",
            index: 3,
            global: global,
          ),

          const Spacer(),
          const Divider(),

          // Add logout or settings later
        ],
      ),
    );
  }

  // ---------------- Drawer Header ------------------------

  Widget _drawerHeader(GlobalProvider global, User? user) {
    return Container(
      decoration: const BoxDecoration(color: Colors.blue),
      child: Column(
        children: [
          // ------- ORIGINAL HEADER --------
          GestureDetector(
            onTap: () {
              global.setCurrentIndex(4);  // Profile
              Navigator.pop(context);
            },
            child: UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(
                user?.name ?? "User Name",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              accountEmail: Text(
                user?.mobile ?? "xxx-xxx-xxxx",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.profileImagePath != null &&
                    user!.profileImagePath!.isNotEmpty
                    ? FileImage(File(user.profileImagePath!))
                    : const AssetImage("assets/images/profile.png")
                as ImageProvider,
              ),
            ),
          ),

          // -------------- EDIT PROFILE BUTTON ----------------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: GestureDetector(
              onTap: () {
                global.setCurrentIndex(4); // navigate to profile
                Navigator.pop(context);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Edit Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ---------------- Drawer Item ------------------------

  Widget _drawerItem({
    required String title,
    required String icon,
    required int index,
    required GlobalProvider global,
  }) {
    return Column(
      children: [
        ListTile(
          leading:  SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(Colors.black ,
              BlendMode.srcIn,
            ),
            fit: BoxFit.contain,
          ),
          title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
          onTap: () {
            global.setCurrentIndex(index);
            Navigator.pop(context);
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Divider(),
        ),
      ],
    );
  }
}
