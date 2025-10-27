import 'dart:io';

import 'package:byaj_khata_book/core/constants/SharedPreferenceKeys.dart';
import 'package:byaj_khata_book/providers/GlobalProvider.dart';
import 'package:byaj_khata_book/providers/HomeProvider.dart';
import 'package:byaj_khata_book/providers/TransactionProvider.dart';
import 'package:byaj_khata_book/providers/TransactionProviderr.dart';
import 'package:byaj_khata_book/providers/UserProvider.dart';
import 'package:byaj_khata_book/providers/bottomNavigationProvider.dart';
import 'package:byaj_khata_book/providers/theme_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/ServiceLocator.dart';
import 'core/routes/router.dart';
import 'package:provider/provider.dart';

import 'data/models/Contact.dart';
import 'data/models/Reminder.dart';
import 'data/models/Transaction.dart';
import 'core/constants/InterestType.dart';
import 'core/constants/ContactType.dart';
import 'core/constants/InterestPeriod.dart';


// Global notification service
// final notificationService = NotificationService.instance;
// // Global key for navigator to use in notification callbacks
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// // Background message handler for FCM
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   await Firebase.initializeApp();
//   print("Handling a background message: ${message.messageId}");
//
//   // Process the message and potentially show a notification
//   await notificationService.handleBackgroundMessage(message);
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize Firebase with better error handling and timeout
//   try {
//     print('===== FIREBASE INIT =====');
//     print('Starting Firebase initialization...');
//     print('Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
// //     // Add timeout to Firebase initialization
//     bool firebaseInitialized = false;
//
//     await Future.any([
//       Firebase.initializeApp(
//         options: const FirebaseOptions(
//           apiKey: 'AIzaSyAyzvrHynsUE5ziad_Se-1IQxyLXptKu3A',
//           appId: '1:586549083907:android:1e440fdfd5589676aa7336',
//           messagingSenderId: '586549083907',
//           projectId: 'my-byaj-book',
//           storageBucket: 'my-byaj-book.firebasestorage.app',
//         ),
//       ).then((_) {
//         firebaseInitialized = true;
//       }),
//       // Timeout after 5 seconds to prevent hanging
//       Future.delayed(const Duration(seconds: 5)).then((_) {
//         if (!firebaseInitialized) {
//           print('Firebase initialization timed out');
//           throw Exception('Firebase initialization timed out');
//         }
//       }),
//     ]);
//     if (firebaseInitialized) {
//       // Setup FCM background message handler
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//       // Initialize Firebase App Check - helps with security and app verification
//       await FirebaseAppCheck.instance.activate(
//         // Use SafetyNet provider for release builds instead of PlayIntegrity
//         androidProvider: kReleaseMode
//             ? AndroidProvider.safetyNet
//             : AndroidProvider.debug,
//         appleProvider: kReleaseMode
//             ? AppleProvider.appAttest
//             : AppleProvider.debug,
//       );
//
//       // Configure Firebase services with proper app information
//       // This helps set the app name in verification messages
//       try {
//         await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
//         // Set the app name for Firebase Auth services
//         FirebaseAuth.instance.setLanguageCode('en'); // Set to your preferred language
//
//         // Request notification permissions using centralized utility instead of direct FCM calls
//         // We'll handle FCM token retrieval after permissions are granted
//         final permissionUtils = PermissionUtils();
//
//         // We need to check context availability since we're in main()
//         if (navigatorKey.currentContext != null) {
//           await permissionUtils.requestNotificationPermission(navigatorKey.currentContext!);
//         } else {
//           // Fallback to direct FCM permission request if context is not available
//           if (Platform.isIOS || Platform.isMacOS) {
//             await FirebaseMessaging.instance.requestPermission(
//               alert: true,
//               badge: true,
//               sound: true,
//               provisional: false,
//             );
//           } else if (Platform.isAndroid) {
//             await FirebaseMessaging.instance.requestPermission();
//           }
//         }
//
//         // Get FCM token for this device
//         String? token = await FirebaseMessaging.instance.getToken();
//         print('FCM Token: $token');
//
//         // Configure FCM foreground notification presentation options
//         await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//           alert: true,
//           badge: true,
//           sound: true,
//         );
//
//         print('Firebase App Check and FCM configured successfully');
//       } catch (appCheckError) {
//         print('Firebase App Check error: $appCheckError');
//       }
//     }
//
//     // Enable Firebase Crashlytics in release mode
//     if (!kDebugMode && firebaseInitialized) {
//       await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
//       FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
//     }
//
//     print('Firebase initialized successfully!');
//   } catch (e, stackTrace) {
//     // More detailed error handling
//     print('===== FIREBASE INIT ERROR =====');
//     print('Failed to initialize Firebase: $e');
//     print('Stack trace: $stackTrace');
//     print('App will continue in local-only mode without Firebase.');
//     print('==============================');
//   }

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await setupDi();

  // Register adapters (after defining models)
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(InterestTypeAdapter());
  Hive.registerAdapter(ContactTypeAdapter());
  Hive.registerAdapter(InterestPeriodAdapter());


  //   print("⚠️ Hive schema changed — deleting old boxes...");
  //   await Hive.deleteBoxFromDisk('contacts');
  //   await Hive.deleteBoxFromDisk('transactions');
  //   await Hive.deleteBoxFromDisk('reminders');
  //   await prefs.setInt('hiveSchemaVersion', hiveSchemaVersion);
  //   print("✅ Hive boxes cleared successfully.");


  await Hive.openBox<Contact>('contacts');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Reminder>('reminders');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider<GlobalProvider>(
          create: (_) => GlobalProvider(),
        ),
        ChangeNotifierProvider<TransactionProviderr>(
          create: (_) => TransactionProviderr(),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}