import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/RouteNames.dart';
import '../core/theme/AppColors.dart';
import '../providers/UserProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the UserProvider with timeout
    _initializeApp();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    // Initialize the UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Create a timeout to ensure app doesn't get stuck
    bool isInitialized = false;

    try {
      // Try to initialize user provider with a timeout
      await Future.any([
        // Normal initialization
        userProvider.initialize().then((_) {
          isInitialized = true;
          debugPrint('User provider initialized successfully');
        }),

        // Timeout after 3 seconds
        Future.delayed(const Duration(seconds: 3)).then((_) {
          if (!isInitialized) {
            debugPrint('User provider initialization timed out');
          }
        }),
      ]);
    } catch (e) {
      debugPrint('Error initializing user provider: $e');
    } finally {
      // Navigate to next screen after a delay regardless of initialization status
      Future.delayed(const Duration(milliseconds: 3000), () {
        _checkUserAndNavigate();
      });
    }
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // The initialize method was called in initState, so user data should be loaded
      final user = userProvider.user;

      // Add debug print to see what's happening
      debugPrint('Splash screen navigation check: user = $user');
      // Simulate small delay (optional)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (user != null) {
        context.go(RouteNames.home);
      } else {
        context.go(RouteNames.login);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in splash screen navigation: $e');
      debugPrint('Stack trace: $stackTrace');

      // Force navigation to login screen if there's an error
      if (mounted) context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Dynamic values
    final logoSize = shortestSide * 0.45;
    final appNameFontSize = shortestSide * 0.08; // ~8% of screen width/height
    final taglineFontSize = shortestSide * 0.04;
    final spacingLarge = shortestSide * 0.07;
    final spacingMedium = shortestSide * 0.03;

    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              height: logoSize,
                              width: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(38),
                                    spreadRadius: 2,
                                    blurRadius: 15,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withAlpha(230),
                                  width: 2,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withAlpha(230),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.asset(
                                  'assets/my_byaj_book_logo.png',
                                  fit: BoxFit.contain,
                                  width: logoSize * 0.8,
                                  height: logoSize * 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacingLarge),

                    // App Name
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Text(
                        'My Byaj Book',
                        style: TextStyle(
                          fontSize: appNameFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: const Offset(2, 2),
                              blurRadius: 3.0,
                              color: Colors.black.withAlpha(77),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: spacingMedium),

                    // Hindi Tagline
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Text(
                        'सरल हिसाब, स्मार्ट ज़िंदगी',
                        style: TextStyle(
                          fontSize: taglineFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: spacingLarge),

                    // Loader
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: SizedBox(
                        width: shortestSide * 0.1,
                        height: shortestSide * 0.1,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withAlpha(230),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: EdgeInsets.only(bottom: spacingMedium * 2),
                child: Column(
                  children: [
                    Text(
                      "powered by",
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: taglineFontSize * 0.8,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: spacingMedium / 2),
                    Text(
                      "RJ Innovative Media",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: taglineFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
