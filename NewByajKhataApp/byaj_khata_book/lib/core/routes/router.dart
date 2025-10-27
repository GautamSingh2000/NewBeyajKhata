import 'package:byaj_khata_book/data/models/Contact.dart';
import 'package:byaj_khata_book/screens/BillDiaryScreen.dart';
import 'package:byaj_khata_book/screens/CardScreen.dart';
import 'package:byaj_khata_book/screens/EmiCalculatorScreen.dart';
import 'package:byaj_khata_book/screens/HistoryScreen.dart';
import 'package:byaj_khata_book/screens/MilkDiaryScreen.dart';
import 'package:byaj_khata_book/screens/SipCalculatorScreen.dart';
import 'package:byaj_khata_book/screens/TaxCalculatorScreen.dart';
import 'package:byaj_khata_book/screens/WorkDiaryScreen.dart';
import 'package:byaj_khata_book/screens/contacts/ContactDetailScreen.dart';
import 'package:byaj_khata_book/screens/contacts/EditContactScreen.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../screens/GlobalScreen.dart';
import '../../screens/Home/HomeScreen.dart';
import '../../screens/LoanScreen.dart';
import '../../screens/LoginScreen.dart';
import '../../screens/contacts/SelectContactScreen.dart';
import '../../screens/SplashScreen.dart';
import '../constants/RouteNames.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return GlobalScreen(child: child);
      },
      routes: [
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: RouteNames.loans,
          builder: (context, state) => const LoanScreen(),
        ),
        GoRoute(
          path: RouteNames.cards,
          builder: (context, state) => const CardScreen(),
        ),
        GoRoute(
          path: RouteNames.billDiary,
          builder: (context, state) => const BillDiaryScreen(),
        ),
        GoRoute(
          path: RouteNames.emiCalc,
          builder: (context, state) => const EmiCalculatorScreen(),
        ),
        GoRoute(
          path: RouteNames.sipCalc,
          builder: (context, state) => const SipCalculatorScreen(),
        ),
        GoRoute(
          path: RouteNames.taxCalc,
          builder: (context, state) => const TaxCalculatorScreen(),
        ),
        GoRoute(
          path: RouteNames.milkDiary,
          builder: (context, state) => const MilkDiaryScreen(),
        ),
        GoRoute(
          path: RouteNames.workDiary,
          builder: (context, state) => const WorkDiaryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.selectContact,
      builder: (context, state) {
        // Get the passed value from `extra` (default to false if null)
        final bool isWithInterest = state.extra as bool? ?? false;
        return SelectContactScreen(isWithInterest: isWithInterest);
      },
    ),
    GoRoute(
      path: RouteNames.editContact,
      builder: (context, state) {
        // Get the passed value from `extra` (default to false if null)
        final extras = state.extra as Map<String, dynamic>;
        final contact = extras['contact'] as Contact;
        final isWithInterest = extras['isWithInterest'] as bool? ?? false;
        return EditContactScreen(
            contact: contact,
            isWithInterest: isWithInterest
        );
      },
    ),
    GoRoute(
      path: RouteNames.contestDetails,
      builder: (context, state) {
        // Get the passed value from `extra` (default to false if null)
        final extras = state.extra as Map<String, dynamic>;
        // final contact = extras['contact'] as Contact;
        final contactId = extras['contactId'] as String;
        final isWithInterest = extras['isWithInterest'] as bool? ?? false;
        final showSetupPrompt = extras['showSetupPrompt'] as bool? ?? false;
        final showTransactionDialogOnLoad =
            extras['showTransactionDialogOnLoad'] as bool? ?? false;
        final dailyInterestNote = extras['dailyInterestNote'] as String?;
        return ContactDetailScreen(
          contactId: contactId,
          showSetupPrompt: showSetupPrompt,
          showTransactionDialogOnLoad: showTransactionDialogOnLoad,
          dailyInterestNote: dailyInterestNote,
            isWithInterest: isWithInterest
        );
      },
    ),
    GoRoute(
      path: RouteNames.contactHistory,
      builder: (context, state) {
        return HistoryScreen();
      },
    ),
  ],
);
